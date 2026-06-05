import 'package:flutter/foundation.dart';
import '../../common/entities/entities.dart';
import '../../common/interfaces/i_inventory_service.dart';  // ← correct interface
import '../../data/services/inventory_data_service.dart';
import '../../data/services/cache_service.dart';
import '../dtos/inventory_dto.dart';
import 'notification_service.dart';

class InventoryService {

  final IInventoryDataService _data = InventoryDataService();
  // ── Inventory CRUD ──────────────────────────────────────────────────────

  Future<List<FoodItem>> fetchInventory() async {
    final settings = _data.loadNotificationSettings();
    try {
      final items = await _data.fetchInventory();
      await _data.saveInventory(items);
      await LocalNotificationService.scheduleAllFromInventory(
        items,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour: settings.dailyReminderTime.hour,      // ← add
        reminderMinute: settings.dailyReminderTime.minute,
      );
      return items;
    } catch (e) {
      debugPrint('[InventoryService] fetch failed: $e — using cache');
      return _data.loadInventory();
    }
  }

  Future<FoodItem> createItem(AddInventoryItemRequest request) async {
    final item     = await _data.createItem(request);
    final settings = _data.loadNotificationSettings();
    await LocalNotificationService.scheduleExpiryNotification(
      item,
      daysBeforeExpiry: settings.alertLeadDays,
      reminderHour: settings.dailyReminderTime.hour,      // ← add
      reminderMinute: settings.dailyReminderTime.minute,
    );
    return item;
  }

  Future<bool> updateItem(
      String inventoryId,
      AddInventoryItemRequest request,
      ) async {
    final success = await _data.updateItem(inventoryId, request);
    if (success) {
      // Reschedule notification — expiry date may have changed
      final items = _data.loadInventory();
      final updated = items.firstWhere(
            (i) => i.id == inventoryId,
        orElse: () => throw Exception('Item not found after update'),
      );
      final settings = _data.loadNotificationSettings();
      await LocalNotificationService.cancelNotification(inventoryId);
      await LocalNotificationService.scheduleExpiryNotification(
        updated,
        daysBeforeExpiry: settings.alertLeadDays,
      );
    }
    return success;
  }

  Future<bool> deleteItem(String inventoryId) async {
    final success = await _data.deleteItem(inventoryId);
    if (success) {
      await LocalNotificationService.cancelNotification(inventoryId);
      await _data.removeItem(inventoryId);
    }
    return success;
  }

  // ── Cache ───────────────────────────────────────────────────────────────

  List<FoodItem> loadCached() => _data.loadInventory();

  // ── Consumed / discarded ────────────────────────────────────────────────

  Future<void> recordConsumed()  => _data.incrementConsumed();
  Future<void> recordDiscarded() => _data.incrementDiscarded();
  int getConsumedCount()         => _data.loadConsumedCount();
  int getDiscardedCount()        => _data.loadDiscardedCount();

  Future<bool> discardItem(String inventoryId) async {
    final success = await _data.deleteItem(inventoryId);  // PATCH /discard
    if (success) {
      await LocalNotificationService.cancelNotification(inventoryId);
      await _data.removeItem(inventoryId);
    }
    return success;
  }

  Future<bool> consumeItem(String inventoryId) async {
    final success = await _data.consumeItem(inventoryId);  // PATCH /consume
    if (success) {
      await LocalNotificationService.cancelNotification(inventoryId);
      await _data.removeItem(inventoryId);
    }
    return success;
  }


  // ── Notification settings ───────────────────────────────────────────────

  NotificationSettings getNotificationSettings() =>
      _data.loadNotificationSettings();

  Future<void> saveNotificationSettings(NotificationSettings settings) =>
      _data.saveNotificationSettings(settings);
}
