import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
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
                          onSaved: (v) => setState(() => _username = v),
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
                          onSaved: (v) => setState(() => _email = v),
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

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 20),

                    // ── App Preferences ──
                    _buildSectionLabel('App Preferences'),
                    _buildCard([

                      ListTile(
                        leading: const Icon(Icons.category_outlined,
                            color: AppColors.mediumBlue, size: 22),
                        title: Text('Default Category',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(defaultCategory,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                        onTap: () => _showCategoryPicker(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                      ),
                      const Divider(indent: 48, height: 1),
                      ListTile(
                        leading: const Icon(Icons.alarm_outlined,
                            color: AppColors.mediumBlue, size: 22),
                        title: Text('Default Alert Days',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('Notify me this many days before expiry',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$alertDays days',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                        onTap: () => _showAlertDaysPicker(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _storage.deleteAll();
                          if (mounted) context.go(AppRoutes.login);
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text('Log Out',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.expired,
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
            onTap: () => _showAvatarOptions(context),
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.mediumBlue.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mediumBlue.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mediumBlue,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.mediumBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 12),
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
            color: AppColors.mediumBlue.withOpacity(0.06),
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
    required ValueChanged<String> onSaved,
  }) {
    final ctrl = TextEditingController(text: initialValue);
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
              TextFormField(
                controller: ctrl,
                keyboardType: keyboardType,
                decoration: InputDecoration(labelText: label),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save',
                onPressed: () {
                  onSaved(ctrl.text.trim());
                  Navigator.pop(ctx);
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  validator: (v) => v != null && v.length < 6
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm New Password'),
                  validator: (v) =>
                      v != newCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Update Password',
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password updated successfully')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
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
            child: Text('Default Category',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...AppStrings.categoriesNoAll.map((cat) {
            final isSelected = ref.read(defaultCategoryProvider) == cat;
            return ListTile(
              title: Text(cat, style: GoogleFonts.poppins(fontSize: 14)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.mediumBlue)
                  : null,
              onTap: () {
                ref.read(defaultCategoryProvider.notifier).state = cat;
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
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

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.mediumBlue),
                title: Text('Take Photo',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.mediumBlue),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.expired),
                title: Text('Remove Photo',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppColors.expired)),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
