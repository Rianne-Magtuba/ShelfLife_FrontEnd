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
  final Set<String> _processingItems = {};

  @override
  Future<List<FoodItem>> build() async {
    final cached = _service.loadCached();
    if (cached.isNotEmpty) state = AsyncValue.data(cached);

    final items = await _service.fetchInventory();
    state = AsyncValue.data(items);

    // Load settings from API so they follow the account, not the device
    final settings = await _service.getNotificationSettings();
    // Also sync to cache for offline use
    await CacheService.saveNotificationSettings(settings);

    if (settings.enabled) {
      await LocalNotificationService.scheduleAllFromInventory(
        items,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour:     settings.dailyReminderTime.hour,
        reminderMinute:   settings.dailyReminderTime.minute,
        frequency:        settings.frequency,
      );
    }

   // await _updatePersistentNotification();
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchInventory());
 //   await _updatePersistentNotification();
  }

  Future<bool> addItem(AddInventoryItemRequest request) async {
    try {
      final newItem = await _service.createItem(request);
      final current = state.value ?? [];
      state = AsyncValue.data([newItem, ...current]);

    //  await _updatePersistentNotification();

      // ← Schedule notification for the newly added item
      final settings = await _service.getNotificationSettings();
      if (settings.enabled) {
        await LocalNotificationService.scheduleExpiryNotification(
          newItem,
          daysBeforeExpiry: settings.alertLeadDays,
          reminderHour:     settings.dailyReminderTime.hour,
          reminderMinute:   settings.dailyReminderTime.minute,
          frequency:        settings.frequency,
        );
        debugPrint('[InventoryNotifier] Scheduled notification for ${newItem.name}');
      }


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
      if (success) {
        await refresh();
     //   await _updatePersistentNotification();
        // ← Reschedule for the updated item with new expiry date
        final settings = await _service.getNotificationSettings();
        if (settings.enabled) {
          final updated = state.value?.firstWhere(
                (i) => i.id == inventoryId,
            orElse: () => throw Exception('Item not found'),
          );
          if (updated != null) {
            await LocalNotificationService.scheduleExpiryNotification(
              updated,
              daysBeforeExpiry: settings.alertLeadDays,
              reminderHour:     settings.dailyReminderTime.hour,
              reminderMinute:   settings.dailyReminderTime.minute,
              frequency:        settings.frequency,
            );
          }
        }
      }
      return success;
    } catch (e) {
      debugPrint('[InventoryNotifier] updateItem error: $e');
      return false;
    }
  }

  Future<bool> discardItem(String inventoryId) async {
    try {
      final current = state.value ?? [];

      final item = current.firstWhere(
            (i) => i.id == inventoryId,
      );

      final success = await _service.deleteItem(inventoryId);

      if (success) {

        if (item.status == ItemStatus.expired) {
          await _service.recordDiscarded();

          await CacheService.incrementDiscardedCategory(
            item.category,
          );
        }

        state = AsyncValue.data(
          current.where((i) => i.id != inventoryId).toList(),
        );
     //   await _updatePersistentNotification();
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
        await CacheService.incrementConsumedDay();
        final current = state.value ?? [];
        final item = current.firstWhere(
              (i) => i.id == inventoryId,
        );
        await CacheService.incrementConsumedCategory(
          item.category,
        );
        state = AsyncValue.data(
          current.where((i) => i.id != inventoryId).toList(),
        );
       // await _updatePersistentNotification();
      }
      return success;
    } catch (e) {
      debugPrint('[InventoryNotifier] consumeItem error: $e');
      return false;
    }
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    await _service.saveNotificationSettings(settings);

    final items = state.value?.isNotEmpty == true
        ? state.value!
        : await _service.fetchInventory();

    debugPrint('[Settings] Saving — enabled: ${settings.enabled}, '
        'leadDays: ${settings.alertLeadDays}, '
        'frequency: ${settings.frequency}');

    if (settings.enabled) {
      debugPrint('[Settings] Scheduling for ${items.length} items');
      await LocalNotificationService.scheduleAllFromInventory(
        items,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour: settings.dailyReminderTime.hour,
        reminderMinute: settings.dailyReminderTime.minute,
        frequency: settings.frequency,
      );
      // await LocalNotificationService.debugAlarmPermission();
      // await LocalNotificationService.debugPending();
   //   await _updatePersistentNotification();
    } else {
      await LocalNotificationService.cancelAll();
      await LocalNotificationService.cancelPersistentNotification();
    }
  }

  // Future<void> _updatePersistentNotification() async {
  //   final settings = await _service.getNotificationSettings();
  //   if (!settings.enabled) {
  //     await LocalNotificationService.cancelPersistentNotification();
  //     return;
  //   }
  //
  //   final items = state.value ?? [];
  //   final expiringSoon = items.where((i) => i.status == ItemStatus.expiringSoon).length;
  //   final expired = items.where((i) => i.status == ItemStatus.expired).length;
  //
  //   await LocalNotificationService.showPersistentNotification(
  //     totalItems: items.length,
  //     expiringSoon: expiringSoon,
  //     expired: expired,
  //   );
  // }
}





// ── Providers ───────────────────────────────────────────────────────────────

final inventoryProvider =
AsyncNotifierProvider<InventoryNotifier, List<FoodItem>>(
  InventoryNotifier.new,
);

final notificationSettingsProvider = FutureProvider<NotificationSettings>((ref) async {
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

class AnalyticsNotifier extends AsyncNotifier<AnalyticsResult> {
  @override
  Future<AnalyticsResult> build() async {
    // Watches inventory — re-runs automatically when inventory changes
    final items = ref.watch(inventoryProvider).value ?? [];
    final service = InventoryService();

    List<FoodItem> consumedItems  = [];
    List<FoodItem> discardedItems = [];

    try {
      final results = await Future.wait([
        service.fetchConsumedItems(),
        service.fetchDiscardedItems(),
      ]);
      consumedItems  = results[0];
      discardedItems = results[1];
    } catch (e) {
      // Network failed — degrade gracefully to cache-only mode
      debugPrint('[Analytics] Backend fetch failed, falling back to cache: $e');
      return AnalyticsService.compute(
        items,
        consumedCount:    CacheService.loadConsumedCount(),
        discardedCount:   CacheService.loadDiscardedCount(),
        consumedTimeline: CacheService.loadConsumedTimeline(),
        wastedByCategory: CacheService.loadDiscardedCategories(),
      );
    }

    // Build wasted-by-category from actual discarded items
    final wastedByCategory = <String, int>{};
    for (final item in discardedItems) {
      wastedByCategory[item.category.label] =
          (wastedByCategory[item.category.label] ?? 0) + 1;
    }

    return AnalyticsService.compute(
      items,
      consumedCount:    consumedItems.length,
      discardedCount:   discardedItems.length,
      consumedTimeline: CacheService.loadConsumedTimeline(),
      wastedByCategory: wastedByCategory,
    );
  }
}

final analyticsProvider =
AsyncNotifierProvider<AnalyticsNotifier, AnalyticsResult>(
  AnalyticsNotifier.new,
);