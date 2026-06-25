import 'package:collection/collection.dart';
import '../../common/entities/entities.dart';

class AnalyticsResult {
  final int totalAdded;
  final int totalExpired;
  final int totalConsumed;
  final int totalDiscarded;
  final double estimatedWasteCost;
  final double consumedRatio;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> wastedByCategory;
  final List<MapEntry<String, int>> expiryByDay;

  const AnalyticsResult({
    required this.totalAdded,
    required this.totalExpired,
    required this.totalConsumed,
    required this.totalDiscarded,
    required this.estimatedWasteCost,
    required this.consumedRatio,
    required this.categoryBreakdown,
    required this.wastedByCategory,
    required this.expiryByDay,
  });

  bool get isEmpty =>
      totalAdded == 0 && totalConsumed == 0 && totalDiscarded == 0;
}

class AnalyticsService {
  /// Called by [analyticsProvider] — receives counts from the business layer,
  /// never imports CacheService or any data layer class directly.
  static AnalyticsResult compute(
      List<FoodItem> activeItems, {
        required int consumedCount,
        required int discardedCount,
        required Map<String, int> wastedByCategory,
        required List<MapEntry<String, int>> consumedTimeline,
      }) {
    // ── Totals ──────────────────────────────────────────────────────────────
    final expired = activeItems
        .where((i) => i.status == ItemStatus.expired)
        .toList();

    final total =
        activeItems.length +
            consumedCount +
            discardedCount;

    // ── Waste cost — sum purchase prices of expired active items ────────────
    final wasteCost = expired.fold<double>(
      0.0,
          (sum, i) => sum + (i.purchasePrice ?? 0.0),
    );

    // ── Consumed ratio ───────────────────────────────────────────────────────
    // Out of items that have left the pantry (consumed + discarded),
    // what fraction was consumed intentionally?
    final actionTotal = consumedCount + discardedCount;
    final consumedRatio =
    actionTotal == 0 ? 0.0 : consumedCount / actionTotal;

    // ── Category breakdown — how many active items per category ─────────────
    final categoryBreakdown = activeItems
        .groupListsBy((i) => i.category.label)
        .map((k, v) => MapEntry(k, v.length));

    // ── Wasted by category — expired active items grouped by category ────────
   // final wastedByCategory = expired
      //  .groupListsBy((i) => i.category.label)
       // .map((k, v) => MapEntry(k, v.length));

    // ── Expiry timeline — items expiring on each of the last 7 days ─────────
 //   final now = DateTime.now();
    // Build an ordered map: oldest day first, today last
   // final dayKeys = List.generate(7, (i) {
     // final d = now.subtract(Duration(days: 6 - i));
     // return _dayKey(d);
 //   });
   // final dayMap = {for (final k in dayKeys) k: 0};

  //  for (final item in activeItems) {
    //  final key = _dayKey(item.expiryDate);
    //  if (dayMap.containsKey(key)) {
     //   dayMap[key] = dayMap[key]! + 1;
     // }
  //  }

    // Convert to list of entries preserving insertion order
 //   final expiryByDay = dayMap.entries.toList();

    return AnalyticsResult(
      totalAdded:         total,
      totalExpired:       expired.length,
      totalConsumed:      consumedCount,
      totalDiscarded:     discardedCount,
      estimatedWasteCost: wasteCost,
      consumedRatio:      consumedRatio,
      categoryBreakdown:  categoryBreakdown,
      wastedByCategory: wastedByCategory,
      expiryByDay: consumedTimeline,
    );
  }

  /// Formats a DateTime to a stable string key: "2025-06-01"
  static String _dayKey(DateTime d) =>
      '${d.year}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  /// Converts a day key back to a short display label: "Mon", "Tue", etc.
  /// Use this in the StatisticsPage bar chart instead of hardcoded day names.
  static String dayKeyToLabel(String key) {
    final parts = key.split('-');
    final date  = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // weekday: Mon=1 … Sun=7
    return labels[date.weekday - 1];
  }
}