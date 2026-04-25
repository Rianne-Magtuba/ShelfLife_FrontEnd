import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../data/models.dart';
import '../data/mock_data.dart';
import '../app/router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockData.items;
    final user = MockData.user;

    final total = items.length;
    final expiringSoon =
        items.where((i) => i.status == ItemStatus.expiringSoon).length;
    final expired = items.where((i) => i.status == ItemStatus.expired).length;
    final urgentItems = items
        .where((i) => i.status != ItemStatus.fresh)
        .toList()
      ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    final recentItems = [...items]
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final recent5 = recentItems.take(5).toList();

    return AppBackground(
      child: Column(
        children: [
          _HomeHeader(user: user, expiredCount: expired),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingM, 16, AppSizes.paddingM, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats bar ──
                  // FIX: Each _StatCard now navigates to /inventory when tapped.
                  _StatsBar(
                    total: total,
                    expiringSoon: expiringSoon,
                    expired: expired,
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 20),

                  // ── Urgent alerts ──
                  if (urgentItems.isNotEmpty) ...[
                    SectionHeader(
                      title: '⚠️ Urgent Alerts',
                      trailing: TextButton(
                        onPressed: () => context.go(AppRoutes.inventory),
                        child: Text('View all',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.mediumBlue)),
                      ),
                    ),
                    // FIX: Pass onTap so the card navigates to item detail.
                    ...urgentItems.take(3).map(
                          (item) => _UrgentAlertCard(
                            item: item,
                            onTap: () => context.push(
                              AppRoutes.itemDetail,
                              extra: item.id,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                        ),
                    const SizedBox(height: 20),
                  ],

                  // ── Recent items ──
                  SectionHeader(
                    title: '📦 Recently Added',
                    trailing: TextButton(
                      onPressed: () => context.go(AppRoutes.inventory),
                      child: Text('View all',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.mediumBlue)),
                    ),
                  ),
                  // FIX: Pass onTap so the tile navigates to item detail.
                  ...recent5.map(
                    (item) => _RecentItemTile(
                      item: item,
                      onTap: () => context.push(
                        AppRoutes.itemDetail,
                        extra: item.id,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Header ──────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final UserProfile user;
  final int expiredCount;

  const _HomeHeader({required this.user, required this.expiredCount});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final notifCount = MockData.notifications.where((n) => !n.isRead).length;

    return Container(
      padding:
          EdgeInsets.only(top: topPad + 12, left: 20, right: 20, bottom: 24),
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
      child: Row(
        children: [
          ProfileAvatar(initials: user.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.displayName?.split(' ').first ?? user.username}! 👋',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => context.go(AppRoutes.notifications),
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
              ),
              if (notifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$notifCount',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int expiringSoon;
  final int expired;

  const _StatsBar(
      {required this.total, required this.expiringSoon, required this.expired});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // FIX: All three stat cards are now tappable and go to inventory.
        _StatCard(
          value: total,
          label: 'Total Items',
          icon: Icons.inventory_2_outlined,
          color: AppColors.mediumBlue,
          onTap: () => context.go(AppRoutes.inventory),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: expiringSoon,
          label: 'Expiring Soon',
          icon: Icons.schedule,
          color: AppColors.expiring,
          onTap: () => context.go(AppRoutes.inventory),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: expired,
          label: 'Expired',
          icon: Icons.warning_outlined,
          color: AppColors.expired,
          onTap: () => context.go(AppRoutes.inventory),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap; // FIX: added

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap, // FIX: added
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // FIX: was missing
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text('$value',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Urgent Alert Card ────────────────────────────────────────────────────────

class _UrgentAlertCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onTap; // FIX: added

  const _UrgentAlertCard({required this.item, this.onTap}); // FIX

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // FIX: was missing entirely
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.status.bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: item.status.color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imagePath ?? 'assets/images/placeholder.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: item.status.color.withOpacity(0.2),
                  child: Icon(item.category.icon,
                      color: item.status.color, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(item.category.label,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: item.status),
                const SizedBox(height: 4),
                Text(
                  item.daysUntilExpiry < 0
                      ? 'Expired'
                      : '${item.daysUntilExpiry}d left',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: item.status.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Item Tile ─────────────────────────────────────────────────────────

class _RecentItemTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onTap; // FIX: added

  const _RecentItemTile({required this.item, this.onTap}); // FIX

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // FIX: was missing entirely
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
                color: AppColors.mediumBlue.withOpacity(0.30),
                blurRadius: 5,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  item.imagePath ?? 'assets/images/placeholder.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: AppColors.lightBlue,
                    child: Icon(item.category.icon,
                        color: item.category.color, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(item.category.label,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ExpiryChip(daysLeft: item.daysUntilExpiry),
          ],
        ),
      ),
    );
  }
}
