import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

// ─── FAQ Data ─────────────────────────────────────────────────────────────────

const List<Map<String, String>> _faqs = [
  {
    'q': 'How do I add items to my inventory?',
    'a':
        'Tap the "+" button on the home screen. You can either scan a barcode of a product with your camera or enter details manually. Fill in the item name, category, quantity, and expiry date.',
  },
  {
    'q': 'When will I receive expiration notifications?',
    'a':
        'You\'ll receive notifications based on your notification settings (found in Profile → Notification Settings). By default, you\'ll be notified 3 days before an item expires.',
  },
  {
    'q': 'How do I edit or delete an item?',
    'a':
        'On the inventory list, tap "Edit" or "Delete" on any item card. You can also swipe left on an item for quick actions.',
  },
  {
    'q': 'What do the different expiry status colors mean?',
    'a':
        'Green = Fresh (more than 3 days left). Orange = Expiring soon (1–3 days left). Red = Expired or expiring today.',
  },
  {
    'q': 'Can I track items in different storage locations?',
    'a':
        'Yes! When adding an item, select the category: Fridge, Pantry, Freezer, or Others. You can filter by category on the inventory screen.',
  },
  {
    'q': 'How do I turn off notifications?',
    'a':
        'Go to Profile → Notification Settings to manage or disable all expiry alerts.',
  },
];

// ─── Scan Steps ───────────────────────────────────────────────────────────────

const List<Map<String, String>> _scanSteps = [
  {
    'title': 'Open Scanner',
    'desc': 'Tap the \'+\' button and select \'Scan Date\' tab',
  },
  {
    'title': 'Position Label',
    'desc': 'Align the barcode within the guide box on screen',
  },
  {
    'title': 'Capture',
    'desc': 'Tap \'Start Scanning\' and hold steady until code is recognized',
  },
  {
    'title': 'Confirm',
    'desc': 'Review the recognized date and tap \'Confirm\' to save',
  },
];

// ─── Help Page ────────────────────────────────────────────────────────────────

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final Set<int> _expanded = {};

  static const String _appVersion = '1.0.0';
  static const String _buildDate = 'June 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const HelpHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildFAQSection(),
                    const SizedBox(height: 20),
                    _buildScanGuide(),
                    const SizedBox(height: 20),
                    _buildAppInfo(context),
                    const SizedBox(height: 20),
                     _buildLegalSection(context),
                    // const SizedBox(height: 20),
                    // // _buildFeedbackButton(context),
                    // const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQ Accordion ──

  Widget _buildFAQSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Frequently Asked Questions'),
          const SizedBox(height: 4),
          ...List.generate(_faqs.length, (i) {
            final isOpen = _expanded.contains(i);
            final isLast = i == _faqs.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: () => setState(
                      () => isOpen ? _expanded.remove(i) : _expanded.add(i)),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_faqs[i]['q']!,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: isOpen
                                      ? FontWeight.w600
                                      : FontWeight.w500)),
                        ),
                        Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isOpen
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_faqs[i]['a']!,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Scan Guide ──

  Widget _buildScanGuide() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: AppColors.mediumBlue, size: 20),
              const SizedBox(width: 8),
              Text('How to Scan Expiry Dates',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_scanSteps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.mediumBlue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_scanSteps[i]['title']!,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_scanSteps[i]['desc']!,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── App Info ──

  Widget _buildAppInfo(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'App Information'),
          const SizedBox(height: 8),
          const _InfoRow(label: 'Version', value: _appVersion),
          const Divider(height: 20, color: AppColors.divider),
          const _InfoRow(label: 'Build Date', value: _buildDate),
          const Divider(height: 20, color: AppColors.divider),
          InkWell(
            onTap: () => _showChangelog(context),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: const _InfoRow(
              label: 'Changelog',
              value: 'View →',
              valueColor: AppColors.mediumBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ── Legal ──

  Widget _buildLegalSection(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Legal'),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openLegal(context, 'Privacy Policy'),
          ),
          const Divider(indent: 48, height: 1, color: AppColors.divider),
          SettingsTile(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            onTap: () => _openLegal(context, 'Terms of Service'),
          ),
        ],
      ),
    );
  }

  // ── Feedback button ──

  // Widget _buildFeedbackButton(BuildContext context) {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: ElevatedButton.icon(
  //       onPressed: () => _openFeedback(context),
  //       icon: const Icon(Icons.mail_outline, size: 18),
  //       label: Text('Contact / Send Feedback',
  //           style:
  //               GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
  //     ),
  //   );
  // }

  // ── Dialogs ──

  void _showChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXL)),
        title: Text('Changelog',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChangelogEntry(
                version: 'v1.0.0',
                date: 'June 2026',
                changes: [
                  'Initial release',
                  'Barcode scan Products',
                  'Push notifications for items',
                  'Statistics & insights dashboard',
                  'An app developed for ADET',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.poppins(color: AppColors.mediumBlue)),
          ),
        ],
      ),
    );
  }

  void _openLegal(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Text(
                  'Though shall not troll in entering product details, wag magaspang. eme hahaha',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _openFeedback(BuildContext context) {
  //   final ctrl = TextEditingController();
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //         borderRadius:
  //             BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL))),
  //     builder: (ctx) => Padding(
  //       padding: EdgeInsets.fromLTRB(
  //           24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Send Feedback',
  //               style: GoogleFonts.poppins(
  //                   fontSize: 18, fontWeight: FontWeight.w700)),
  //           const SizedBox(height: 4),
  //           Text('We\'d love to hear from you!',
  //               style: GoogleFonts.poppins(
  //                   fontSize: 13, color: AppColors.textSecondary)),
  //           const SizedBox(height: 16),
  //           TextFormField(
  //             controller: ctrl,
  //             maxLines: 5,
  //             decoration: const InputDecoration(
  //               hintText: 'Describe your issue or suggestion...',
  //               alignLabelWithHint: true,
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           PrimaryButton(
  //             label: 'Send',
  //             icon: Icons.send,
  //             onPressed: () {
  //               Navigator.pop(ctx);
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(content: Text('Feedback sent! Thank you.')),
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.mediumBlue.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  const _CardTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title,
          style:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _ChangelogEntry extends StatelessWidget {
  final String version;
  final String date;
  final List<String> changes;

  const _ChangelogEntry(
      {required this.version, required this.date, required this.changes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(version,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlue)),
            ),
            const SizedBox(width: 8),
            Text(date,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ...changes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.mediumBlue)),
                  Expanded(
                    child: Text(c,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class HelpHeader extends StatelessWidget {
  const HelpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkBlue, AppColors.mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding:
          EdgeInsets.only(top: topPad + 12, left: 8, right: 20, bottom: 20),
      child: Row(
        children: [
          // FIX: Back button — same reasoning as StatisticsHeader above.
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              'Help & About',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
