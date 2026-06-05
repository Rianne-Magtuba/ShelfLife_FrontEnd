import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/entities/entities.dart';
import '../../data/services/cache_service.dart';
import '../services/analytics_service.dart';
import '../services/inventory_service.dart';
import '../dtos/inventory_dto.dart';
import '../services/notification_service.dart';

class InventoryNotifier extends AsyncNotifier<List<FoodItem>> {
  final _service = InventoryService();

  @override
  Future<List<FoodItem>> build() async {
    final cached = _service.loadCached();
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
      final success = await _service.updateItem(inventoryId, request);
      if (success) await refresh();
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
        await _service.recordDiscarded();
        final current = state.value ?? [];
        state = AsyncValue.data(
          current.where((i) => i.id != inventoryId).toList(),
        );
      }
      return success;
    } catch (e) {
      debugPrint('[InventoryNotifier] discardItem error: $e');
      return false;
    }
  }

  Future<bool> consumeItem(String inventoryId) async {
    try {
      final success = await _service.consumeItem(inventoryId); // ← was deleteItem
      if (success) {
        await _service.recordConsumed();
        final current = state.value ?? [];
        state = AsyncValue.data(
          current.where((i) => i.id != inventoryId).toList(),
        );
      }
      return success;
    } catch (e) {
      debugPrint('[InventoryNotifier] consumeItem error: $e');
      return false;
    }
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    await _service.saveNotificationSettings(settings);
    final items = state.value ?? [];
    debugPrint('[Settings] Saving — enabled: ${settings.enabled}, leadDays: ${settings.alertLeadDays}');
    if (settings.enabled) {
      debugPrint('[Settings] Scheduling for ${items.length} items');
      await LocalNotificationService.scheduleAllFromInventory(
        items,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour: settings.dailyReminderTime.hour,
        reminderMinute: settings.dailyReminderTime.minute,
      );
    } else {
      await LocalNotificationService.cancelAll();
    }
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final inventoryProvider =
AsyncNotifierProvider<InventoryNotifier, List<FoodItem>>(
  InventoryNotifier.new,
);

final notificationSettingsProvider = StateProvider<NotificationSettings>((ref) {
  return InventoryService().getNotificationSettings();
});

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

final analyticsProvider = Provider<AnalyticsResult>((ref) {
  final items   = ref.watch(inventoryProvider).value ?? [];
  final service = InventoryService();
  return AnalyticsService.compute(
    items,
    consumedCount:  service.getConsumedCount(),
    discardedCount: service.getDiscardedCount(),
  );
});