import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/entities/entities.dart';
import '../../data/services/cache_service.dart';
import '../services/inventory_service.dart';
import '../dtos/inventory_dto.dart';

class InventoryNotifier extends AsyncNotifier<List<FoodItem>> {
  final _service = InventoryService();

  @override
  Future<List<FoodItem>> build() async {
    final cached = CacheService.loadInventory();
    if (cached.isNotEmpty) state = AsyncValue.data(cached);
    return _service.fetchInventory();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchInventory());
  }

  Future<bool> addItem(AddInventoryItemRequest request) async {
    try {
      final newItem = await _service.createItem(request);
      final current = state.value ?? [];
      state = AsyncValue.data([newItem, ...current]);
      return true;
    } catch (e) {
      debugPrint('[InventoryNotifier] addItem error: $e'); 
      return false;
    }
  }

  Future<bool> updateItem(
    String inventoryId,
    AddInventoryItemRequest request,
    ) async {
    try {
      final success = await _service.updateItem(
      inventoryId,
      request,
    );

    if (success) {
      await refresh(); // reload inventory from backend
    }

    return success;
      } catch (e) {
      debugPrint('[InventoryNotifier] updateItem error: $e');
      return false;
      }
    }

  Future<bool> discardItem(String inventoryId) async {
    try {
      final success = await _service.deleteItem(inventoryId);
      if (success) {
        final current = state.value ?? [];
        state = AsyncValue.data(
          current.where((i) => i.id != inventoryId).toList(),
        );
        await CacheService.removeItem(inventoryId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final inventoryProvider =
AsyncNotifierProvider<InventoryNotifier, List<FoodItem>>(
  InventoryNotifier.new,
);

// Derived — notifications come from inventory, no separate API call
final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final items = ref.watch(inventoryProvider).value ?? [];
  final now   = DateTime.now();
  final notifs = <AppNotification>[];

  for (final item in items) {
    if (item.status == ItemStatus.expired) {
      notifs.add(AppNotification(
        id: 'exp_${item.id}', itemId: item.id, itemName: item.name,
        message:  '${item.name} has expired',
        subtitle: 'Remove it from your ${item.category.label}',
        timestamp: now, isRead: false,
        type: NotificationType.expired, daysLeft: item.daysUntilExpiry,
      ));
    } else if (item.status == ItemStatus.expiringSoon) {
      notifs.add(AppNotification(
        id: 'soon_${item.id}', itemId: item.id, itemName: item.name,
        message:  '${item.name} expiring soon',
        subtitle: '${item.daysUntilExpiry} day(s) left',
        timestamp: now, isRead: false,
        type: NotificationType.expiringSoon, daysLeft: item.daysUntilExpiry,
      ));
    }
  }

  return notifs;
});

// Derived — statistics computed locally from inventory
final statisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final items = ref.watch(inventoryProvider).value ?? [];

  final categoryBreakdown = <String, int>{};
  final wastedByCategory  = <String, int>{};
  double wasteCost = 0;
  int expired = 0;

  for (final item in items) {
    final cat = item.category.label;
    categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + 1;
    if (item.status == ItemStatus.expired) {
      expired++;
      wastedByCategory[cat] = (wastedByCategory[cat] ?? 0) + 1;
      if (item.purchasePrice != null) wasteCost += item.purchasePrice!;
    }
  }

  return {
    'totalAdded':         items.length,
    'totalExpired':       expired,
    'totalConsumed':      items.length - expired,
    'estimatedWasteCost': wasteCost,
    'categoryBreakdown':  categoryBreakdown,
    'wastedByCategory':   wastedByCategory,
  };
});

