import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../common/entities/food_item.dart';
import '../../common/interfaces/i_inventory_service.dart';
import '../dtos/inventory_dto.dart';
import '../../data/services/api_client.dart';
import '../../data/services/cache_service.dart';
import '../../data/services/notification_service.dart';
import '../../common/entities/entities.dart';
import '../dtos/user_dto.dart';

class InventoryService implements IInventoryService {
  @override
  Future<List<FoodItem>> getInventory() async {
    try {
      final response = await ApiClient.get('/api/inventory');

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        final items = jsonList
            .map((j) => InventoryItemResponse.fromJson(j as Map<String, dynamic>).toFoodItem())
            .toList();
        await CacheService.saveInventory(items);
        await LocalNotificationService.scheduleAllFromInventory(items);
        return items;
      } else {
        debugPrint('[Inventory] API returned ${response.statusCode} — loading from cache');
        return CacheService.loadInventory(); // ← fallback so UI still shows
      }
    } catch (e) {
      debugPrint('[Inventory] Error: $e — loading from cache');
      return CacheService.loadInventory();
    }
  }

  @override
  Future<FoodItem> addItem(AddInventoryItemRequest request) async {
    final response = await ApiClient.post('/api/inventory', request.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final item = InventoryItemResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      ).toFoodItem();

      await LocalNotificationService.scheduleExpiryNotification(item);
      return item;
    } else {
      throw Exception(ApiClient.parseError(response, 'Failed to add item.'));
    }
  }

  @override
  Future<bool> discardItem(String inventoryId) async {
    final response = await ApiClient.delete('/api/inventory/$inventoryId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      await LocalNotificationService.cancelNotification(inventoryId);
      await CacheService.removeItem(inventoryId);
      return true;
    } else {
      return false;
    }
  }
}