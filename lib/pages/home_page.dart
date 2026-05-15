import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../core/common/entities/entities.dart';
import '../core/business/providers/inventory_provider.dart';
import '../app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends ConsumerStatefulWidget  {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _storage = const FlutterSecureStorage();
  String _username = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await _storage.read(key: 'username') ?? '';
    final email    = await _storage.read(key: 'email')    ?? '';
    if (mounted) setState(() {
      _username = username;
      _email    = email;
    });
  }

  @override
Widget build(BuildContext context) {
  final inventoryAsync = ref.watch(inventoryProvider);
  final notifCount = ref.watch(notificationsProvider).length;

  return AppBackground(
    child: Column(
      children: [
        _HomeHeader(
          username: _username,
          expiredCount: 0,
          notifCount: notifCount,
        ),
        Expanded(
          child: inventoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            // ─── 1. UPDATED ERROR STATE WITH RETRY BUTTON ───
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Could not connect',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: Text(e.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    // 👇 This line is the magic. It forces Riverpod to wipe the cache and run getInventory() again!
                    onPressed: () => ref.invalidate(inventoryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),

            data: (items) {
              if (items.isEmpty) {
                // ── Empty state ──
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_box_outlined,
                          size: 72, color: AppColors.lightBlue),
                      const SizedBox(height: 16),
                      Text('Add your Product',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Tap the + button to add your first item',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ).animate().fadeIn(),
                );
              }

              final total        = items.length;
              final expiringSoon = items.where((i) => i.status == ItemStatus.expiringSoon).length;
              final expired      = items.where((i) => i.status == ItemStatus.expired).length;
              final urgentItems  = items.where((i) => i.status != ItemStatus.fresh).toList()
                ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
              final recent5 = ([...items]
                ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)))
                  .take(5).toList();

              // ─── 2. WRAPPED IN REFRESH INDICATOR ───
              return RefreshIndicator(
                  onRefresh: () async {
                    // 👇 Allows users to pull down on the list to fetch fresh data
                    ref.invalidate(inventoryProvider);
                  },
                  child: SingleChildScrollView(
                    // 👇 AlwaysScrollableScrollPhysics is required for pull-to-refresh to work
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingM, 16, AppSizes.paddingM, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatsBar(
                          total: total,
                          expiringSoon: expiringSoon,
                          expired: expired,
                        ).animate().fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 20),
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
                      ...urgentItems.take(3).map(
                        (item) => _UrgentAlertCard(
                          item: item,
                          onTap: () => context.push(AppRoutes.itemDetail, extra: item.id),
                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SectionHeader(
                      title: '📦 Recently Added',
                      trailing: TextButton(
                        onPressed: () => context.go(AppRoutes.inventory),
                        child: Text('View all',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.mediumBlue)),
                      ),
                    ),
                    ...recent5.map(
                      (item) => _RecentItemTile(
                        item: item,
                        onTap: () => context.push(AppRoutes.itemDetail, extra: item.id),
                      ).animate().fadeIn(delay: 150.ms),
                    ),
                  ],
                ),
              ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}

// ─── Home Header ──────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String username;
  final int expiredCount;
  final int notifCount;

  const _HomeHeader({
    required this.username,
    required this.expiredCount,
    required this.notifCount,  // ← add this
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // Initials from username
    final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.only(top: topPad + 12, left: 20, right: 20, bottom: 24),
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
          // ── Default profile icon instead of image ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $username! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
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
