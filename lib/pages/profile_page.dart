import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../core/business/dtos/user_dto.dart';
import '../core/business/providers/inventory_provider.dart';
import '../core/business/services/auth_logicservice.dart';
import '../core/data/services/cache_service.dart';
import '../widgets/shared_widgets.dart';
import '../app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/responsive_extensions.dart';

// ─── Providers ────────────────────────────────────────────────────────────────


final defaultCategoryProvider = StateProvider<String>((ref) => 'Fridge');
final defaultAlertDaysProvider = StateProvider<int>((ref) => 3);

// ─── Profile Page ─────────────────────────────────────────────────────────────

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String _displayName = '';
  String _email = '';
  String _username = '';

  // Add this
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Add this method
  Future<void> _loadUserData() async {
    final username = await _storage.read(key: 'username') ?? '';
    final email    = await _storage.read(key: 'email')    ?? '';

    if (mounted) {
      setState(() {
        _username    = username;
        _email       = email;
        _displayName = username; // use username as display name since
        // your Firestore has no displayName field
      });
    }
  }



  @override
  Widget build(BuildContext context) {

    final defaultCategory = ref.watch(defaultCategoryProvider);
    final alertDays = ref.watch(defaultAlertDaysProvider);

    // FIX: Get bottom nav bar height so content is never clipped beneath it.
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            AppHeader(
              title: 'Profile',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => _showEditProfileSheet(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                // FIX: Add bottom padding = nav bar height + extra breathing room.
                padding: EdgeInsets.fromLTRB(
                  AppSizes.paddingM,
                  AppSizes.paddingM,
                  AppSizes.paddingM,
                  bottomPad + 30, // 30 accounts for extra breathing room
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildAvatarCard(),
                    const SizedBox(height: 20),

                    // ── Account Details ──
                    _buildSectionLabel('Account Details'),
                    _buildCard([
                      SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Username',
                        subtitle: _username,
                        onTap: () => _showEditField(
                          context,
                          label: 'Username',
                          initialValue: _username,
                          onSaved: (v) async {
                            try {

                              await AuthService().updateProfile(
                                UpdateProfileRequest(
                                  username: v,
                                  email: _email,
                                ),
                              );

                              await _loadUserData();

                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                    ),
                                  ),
                                );
                              }

                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text('$e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const Divider(indent: 48, height: 1),
                      SettingsTile(
                        icon: Icons.mail_outline,
                        title: 'Email',
                        subtitle: _email,
                        onTap: () => _showEditField(
                          context,
                          label: 'Email',
                          initialValue: _email,
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) async {          // ← make it async
                            try {
                              await AuthService().updateProfile(
                                UpdateProfileRequest(
                                  username: _username,  // keep current username
                                  email: v,             // new email
                                ),
                              );
                              await _loadUserData();    // refresh from secure storage
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Email updated successfully')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const Divider(indent: 48, height: 1),
                      SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notification Settings',
                        // FIX: Use context.push() so the back button in
                        // NotificationSettingsPage correctly returns here
                        // instead of jumping to the shell root.
                        onTap: () =>
                            context.push(AppRoutes.notificationSettings),
                      ),
                      const Divider(indent: 48, height: 1),
                      SettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        isBold: true,
                        onTap: () => _showChangePasswordSheet(context),
                      ),
                    ]),

                  SizedBox(height: context.h(0.024)),

                    // ── Features ──
                    _buildSectionLabel('Features'),
                    _buildCard([
                      SettingsTile(
                        icon: Icons.bar_chart_outlined,
                        title: 'Statistics & Insights',
                        // FIX: push, not go — preserves the back-stack so
                        // the back button in StatisticsPage returns here.
                        onTap: () => context.push(AppRoutes.statistics),
                      ),
                      const Divider(indent: 48, height: 1),
                      SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & About',
                        // FIX: same — push keeps the stack intact.
                        onTap: () => context.push(AppRoutes.help),
                      ),
                    ]),

                    SizedBox(height: context.h(0.024)),

                    // ── App Preferences ──
                    // _buildSectionLabel('App Preferences'),
                    // _buildCard([
                    //
                    //
                    //   ListTile(
                    //     leading: const Icon(Icons.alarm_outlined,
                    //         color: AppColors.mediumBlue, size: 22),
                    //     title: Text('Default Alert Days',
                    //         style: GoogleFonts.poppins(
                    //             fontSize: 14, fontWeight: FontWeight.w500)),
                    //     subtitle: Text('Notify me this many days before expiry',
                    //         style: GoogleFonts.poppins(
                    //             fontSize: 12, color: AppColors.textSecondary)),
                    //     trailing: Row(
                     //     mainAxisSize: MainAxisSize.min,
                      //    children: [
                       //     Text('$alertDays days',
                         //       style: GoogleFonts.poppins(
                         //           fontSize: 13,
                             //       color: AppColors.textSecondary)),
                         //   const Icon(Icons.chevron_right,
                          //      color: AppColors.textSecondary),
                        //  ],
                    //    ),
                    //    onTap: () => _showAlertDaysPicker(context),
                    //    contentPadding: const EdgeInsets.symmetric(
                     //       horizontal: 4, vertical: 2),
                   //   ),
                  //  ]),



                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                          onPressed: () async {
                            await CacheService.clearAllData();    // ← full wipe
                            await _storage.deleteAll();
                            ref.invalidate(inventoryProvider);
                            if (mounted) context.go(AppRoutes.login);
                          },
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text('Log Out',
                            style: GoogleFonts.poppins( fontSize: 15, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.expired,
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: AppColors.expired, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusL),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

  // ── Helpers ──

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.mediumBlue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            child: Stack(
              children: [
                ProfileAvatar(
                  name: _displayName,
                  size: 64
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                      width: 20,
                      height: 20
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(_email,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.mediumBlue.withOpacity(0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── Dialogs / Sheets ──

  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _displayName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save Changes',
                onPressed: () {
                  setState(() => _displayName = nameCtrl.text.trim());
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditField(
    BuildContext context, {
    required String label,
    required String initialValue,
    TextInputType keyboardType = TextInputType.text,
        required Future<void> Function(String) onSaved,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit $label',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: label,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return '$label is required';
                    }

                    if (label == 'Username' && text.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (label == 'Email') {

                      final emailRegex = RegExp(
                        r'^[^@]+@[^@]+\.[^@]+$',
                      );

                      if (!emailRegex.hasMatch(text)) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;

                  },
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save',
                onPressed: () async {                    // ← async
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);                    // ← pop first, dismiss keyboard
                  await onSaved(ctrl.text.trim());       // ← then await the backend call
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
      builder: (ctx) =>  Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: SafeArea(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: context.h(0.019)),
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: context.h(0.014)),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  validator: (v) {

                    final value = v?.trim() ?? '';

                    if (value.isEmpty) {
                      return 'Required';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),
                SizedBox(height: context.h(0.014)),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm New Password'),
                  validator: (v) {

                    if (v == null || v.isEmpty) {
                      return 'Confirm your password';
                    }

                    if (v != newCtrl.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),
                SizedBox(height: context.h(0.024)),
                PrimaryButton(
                  label: 'Update Password',
                  onPressed: () async {
                    FocusScope.of(ctx).unfocus();
                    if (formKey.currentState!.validate()) {
                      try {
                        await AuthService().changePassword(
                          ChangePasswordRequest(
                            currentPassword: currentCtrl.text.trim(),
                            newPassword: newCtrl.text.trim(),
                          ),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password changed successfully')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }


  void _showAlertDaysPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Text('Default Alert Days',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...AppStrings.alertLeadTimes.map((days) {
            final isSelected = ref.read(defaultAlertDaysProvider) == days;
            return ListTile(
              title: Text('$days day${days > 1 ? 's' : ''} before expiry',
                  style: GoogleFonts.poppins(fontSize: 14)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.mediumBlue)
                  : null,
              onTap: () {
                ref.read(defaultAlertDaysProvider.notifier).state = days;
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXL)),
        title: Text('Log Out',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expired),
            child: Text('Log Out',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
