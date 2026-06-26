import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../core/common/entities/entities.dart';
import '../core/business/providers/inventory_provider.dart';
import '../app/router.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {


  @override
  void initState() {
    super.initState();
  }



  String _timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

@override
Widget build(BuildContext context) {

  final notifications = ref.watch(notificationsProvider);
  final unreadCount   = notifications.where((n) => !n.isRead).length;

  return AppBackground(
    child: Column(
      children: [
        AppHeader(
          title: unreadCount > 0 ? 'Expiry Alerts' : 'Expiry Alerts',

          // actions: [
          //   IconButton(
          //     onPressed: () => context.push(AppRoutes.notificationSettings),
          //     icon: const Icon(Icons.notifica, color: Colors.white),
          //   ),
          // ],

        ),
        const SizedBox(height: 12),
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Empty state — replace the Column children:
                      const Icon(Icons.crisis_alert, size: 72, color: AppColors.lightBlue),
                      const SizedBox(height: 16),
                      Text('No Alerts',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text("All your items are fresh — great job!",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ).animate().fadeIn(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final notif = notifications[i];
                    return _NotificationCard(
                      notif: notif,
                      timeAgo: _timeAgo(notif.timestamp),
                      onTap: () => context.push(AppRoutes.itemDetail, extra: notif.itemId),
                    ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1);
                  },
                ),
        ),
      ],
    ),
  );
}
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notif;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notif,
    required this.timeAgo,
    required this.onTap,
  });

  Color get _accentColor {
    switch (notif.type) {
      case NotificationType.expired:   return AppColors.expiredBg;
      case NotificationType.expiringSoon: return AppColors.expiringBg;
      default: return AppColors.lightBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: notif.type.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.mediumBlue.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(notif.type.icon, color: notif.type.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.message,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: notif.type.color)),
                  const SizedBox(height: 2),
                  Text(notif.subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(timeAgo,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (notif.daysLeft != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${notif.daysLeft}',
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: notif.type.color)),
                  Text(
                    notif.daysLeft == 0 ? 'expired' : 'days left',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: notif.type.color),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: notif.type.color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
