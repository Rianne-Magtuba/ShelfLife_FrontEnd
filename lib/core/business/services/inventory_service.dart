import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../common/entities/food_item.dart';
import '../../common/interfaces/i_inventory_service.dart';
import '../dtos/inventory_dto.dart';
import '../../data/services/api_client.dart';
import '../../data/services/cache_service.dart';
import '../../data/services/notification_service.dart';
import '../../common/entities/entities.dart';

class InventoryService implements IInventoryService {

  
  @override
  Future<List<FoodItem>> getInventory() async {
    try {
      final response = await ApiClient.get('/api/inventory/pantry');

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
      debugPrint('[InventoryService] addItem response body: ${response.body}');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Backend returns just a success message, not the created item
      if (json.containsKey('message') && json.length == 1) {
        debugPrint('[InventoryService] Backend returned success message: ${json['message']}');
        // Build the item locally from the request and return it
        // This ensures the item is added to local state immediately
        return FoodItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: request.customName ?? 'Item',
          category: _parseCategory(request.customCategory ?? 'Others'),
          quantity: request.quantity,
          weight: request.customWeightGrams?.toStringAsFixed(0),
          weightUnit: request.customWeightGrams != null ? 'g' : null,
          expiryDate: request.expirationDate,
          dateAdded: DateTime.now(),
          purchasePrice: request.customPrice,
          notes: request.notes.isNotEmpty ? request.notes : null,
        );
      }

      // Backend returns the created item object
      final item = InventoryItemResponse.fromJson(json).toFoodItem();

      await LocalNotificationService.scheduleExpiryNotification(item);
      return item;
    } else {
      throw Exception(ApiClient.parseError(response, 'Failed to add item.'));
    }
  }

  static ItemCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fridge':  return ItemCategory.fridge;
      case 'pantry':  return ItemCategory.pantry;
      case 'freezer': return ItemCategory.freezer;
      default:        return ItemCategory.others;
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