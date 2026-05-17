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
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    
    // 1. Parse the backend response using your fixed DTO
    final itemResponse = InventoryItemResponse.fromJson(json);

    // 2. Map the DTO to your local FoodItem model
    return FoodItem(
      id: itemResponse.inventoryId, // Guaranteed to be the real Firestore ID now
      name: itemResponse.displayName,
      category: _parseCategory(itemResponse.displayCategory),
      quantity: itemResponse.quantity,
      weight: itemResponse.weightGrams?.toStringAsFixed(0),
      weightUnit: itemResponse.weightGrams != null ? 'g' : null,
      expiryDate: itemResponse.expirationDate,
      dateAdded: itemResponse.dateRegistered,
      purchasePrice: itemResponse.displayPrice,
      notes: itemResponse.notes.isNotEmpty ? itemResponse.notes : null,
    );
  }

  throw Exception('Failed to add item to inventory. Status: ${response.statusCode}');
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