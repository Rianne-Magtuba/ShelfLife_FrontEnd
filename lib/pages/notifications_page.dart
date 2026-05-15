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
          title: 'Notifications ${unreadCount > 0 ? "($unreadCount)" : ""}',
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.notificationSettings),
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
            ),
          ],

        ),
        const SizedBox(height: 12),
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none,
                          size: 72, color: AppColors.lightBlue),
                      const SizedBox(height: 16),
                      Text('No Notifications',    // ← changed
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text("Your pantry is in good shape!",
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
                      onViewItem: () => context.push(
                          AppRoutes.itemDetail, extra: notif.itemId),
                      onRead: () {}, // derived provider — no local isRead needed
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
  final VoidCallback onViewItem;
  final VoidCallback onRead;

  const _NotificationCard({
    required this.notif,
    required this.timeAgo,
    required this.onViewItem,
    required this.onRead,
  });

  Color get _borderColor {
    switch (notif.type) {
      case NotificationType.expired:
        return AppColors.expiredBg;
      case NotificationType.expiringSoon:
        return AppColors.expiringBg;
      case NotificationType.consumed:
        return AppColors.freshBg;
      case NotificationType.added:
        return AppColors.lightBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRead,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : _borderColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: notif.type.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: AppColors.mediumBlue.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread dot
                if (!notif.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: notif.type.color, shape: BoxShape.circle),
                  ),
                // Item thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/placeholder.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.lightBlue,
                      child: const Icon(Icons.fastfood_outlined,
                          color: AppColors.mediumBlue, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(notif.type.icon,
                              color: notif.type.color, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              notif.message,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: notif.type.color),
                            ),
                          ),
                          if (notif.daysLeft != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${notif.daysLeft}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: notif.type.color)),
                                Text(
                                    notif.daysLeft == 0
                                        ? 'expired'
                                        : 'days left',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: notif.type.color)),
                              ],
                            ),
                        ],
                      ),
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
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            TextButton.icon(
              onPressed: onViewItem,
              icon: const Icon(Icons.visibility_outlined,
                  size: 16, color: AppColors.mediumBlue),
              label: Text('View Item',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.mediumBlue)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.mediumBlue,
                  padding: const EdgeInsets.symmetric(vertical: 4)),
            ),
          ],
        ),
      ),
    );
  }
}
