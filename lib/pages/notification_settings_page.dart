import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../core/business/providers/inventory_provider.dart';
import '../core/business/services/inventory_service.dart';
import '../widgets/shared_widgets.dart';
import '../core/common/entities/entities.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = InventoryService().getNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.darkBlue, AppColors.mediumBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20)),
                  Text('Notification Settings',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                children: [
                  _SettingsSection(
                    title: 'General',
                    children: [
                      SwitchListTile(
                        value: _settings.enabled,
                        onChanged: (v) => setState(
                            () => _settings = _settings.copyWith(enabled: v)),
                        title: Text('Enable Notifications',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('Receive expiry alerts and reminders',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary)),
                        activeThumbColor: AppColors.mediumBlue,
                        secondary: const Icon(Icons.notifications_outlined,
                            color: AppColors.mediumBlue),
                      ),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Alert Lead Time',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notify me X days before expiry',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: AppStrings.alertLeadTimes.map((days) {
                                final selected =
                                    _settings.alertLeadDays == days;
                                return GestureDetector(
                                  onTap: () => setState(() => _settings =
                                      _settings.copyWith(alertLeadDays: days)),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.mediumBlue
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusM),
                                      border: Border.all(
                                          color: selected
                                              ? AppColors.mediumBlue
                                              : AppColors.divider),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('$days',
                                            style: GoogleFonts.poppins(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color: selected
                                                    ? Colors.white
                                                    : AppColors.darkBlue)),
                                        Text('day${days > 1 ? 's' : ''}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: selected
                                                    ? Colors.white70
                                                    : AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Daily Reminder',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time,
                            color: AppColors.mediumBlue),
                        title: Text('Reminder Time',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                            _settings.dailyReminderTime.format(context),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary)),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context,
                              initialTime: _settings.dailyReminderTime);
                          if (t != null) {
                            setState(() => _settings =
                                _settings.copyWith(dailyReminderTime: t));
                          }
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Notification Frequency',
                    children: [
                      ...[
                        (
                          'once',
                          'Once per item',
                          'Send one alert per expiring item'
                        ),
                        (
                          'daily',
                          'Daily digest',
                          'Group alerts into one daily summary'
                        ),
                        (
                          'realtime',
                          'Real-time',
                          'Notify immediately when expiry is near'
                        ),
                      ].map((option) => RadioListTile<String>(
                            value: option.$1,
                            groupValue: _settings.frequency,
                            onChanged: (v) => setState(() =>
                                _settings = _settings.copyWith(frequency: v)),
                            title: Text(option.$2,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text(option.$3,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            activeColor: AppColors.mediumBlue,
                          )),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Save Settings',
                    onPressed: () async {
                      await ref.read(inventoryProvider.notifier).saveSettings(_settings);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved!')),
                        );
                        context.pop();
                      }
                    },
                  ).animate().fadeIn(delay: 250.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                  color: AppColors.mediumBlue.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
