import 'package:flutter/foundation.dart';
import '../../common/entities/entities.dart';
import '../../common/interfaces/i_inventory_service.dart';  // ← correct interface
import '../../data/services/api_client.dart';
import '../../data/services/inventory_data_service.dart';
import '../../data/services/cache_service.dart';
import '../../data/services/user_data_service.dart';
import '../dtos/inventory_dto.dart';
import '../dtos/product_dto.dart';
import 'notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InventoryService {

  final IInventoryDataService _data = InventoryDataService();
  final UserDataService _userDataService = UserDataService();

  // ── Inventory CRUD ──────────────────────────────────────────────────────

  Future<List<FoodItem>> fetchInventory() async {
    final settings = await getNotificationSettings();
    try {
      final items = await _data.fetchInventory();
      await _data.saveInventory(items);
      await LocalNotificationService.scheduleAllFromInventory(
        items,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour: settings.dailyReminderTime.hour,      // ← add
        reminderMinute: settings.dailyReminderTime.minute,
        frequency:        settings.frequency,
      );
      return items;
    } catch (e) {
      debugPrint('[InventoryService] fetch failed: $e — using cache');
      return _data.loadInventory();
    }
  }

  Future<FoodItem> createItem(AddInventoryItemRequest request) async {
    final item     = await _data.createItem(request);
    final settings = await getNotificationSettings();
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
      // Fetch fresh inventory from backend
      final freshItems = await _data.fetchInventory();

      // Update cache with fresh data
      await _data.saveInventory(freshItems);

      final updated = freshItems.firstWhere(
            (i) => i.id == inventoryId,
        orElse: () => throw Exception('Updated item not found'),
      );

      final settings = await getNotificationSettings();

      await LocalNotificationService.cancelNotification(inventoryId);

      await LocalNotificationService.scheduleExpiryNotification(
        updated,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour: settings.dailyReminderTime.hour,
        reminderMinute: settings.dailyReminderTime.minute,
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

  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _userDataService.getNotificationSettings();
    } catch (e) {
      debugPrint('[Settings] API failed, using cache: $e');
      return CacheService.loadNotificationSettings();
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    await Future.wait([
      _userDataService.saveNotificationSettings(settings),
      CacheService.saveNotificationSettings(settings),
    ]);
  }

  //----send request info change method

  Future<void> sendCorrectionRequest({
    required String barcode,
    required String proposedName,
    required String proposedCategory,
    required String proposedWeightGrams,
    required String proposedPrice,
  }) async {
    final response = await ApiClient.post(
      '/api/ProductUpdate',
      ProductUpdateRequest(
        barcode:             barcode,
        proposedName:        proposedName,
        proposedCategory:    proposedCategory,
        proposedWeightGrams: double.tryParse(proposedWeightGrams) ?? 0,
        proposedPrice:       double.tryParse(proposedPrice) ?? 0,
      ).toJson(),
    );

    if (response.statusCode == 200) {
      debugPrint('[InventoryService] Correction request submitted');
      return;
    }

    throw Exception(
      ApiClient.parseError(response, 'Failed to submit correction request.'),
    );
  }


}
