import 'package:flutter/foundation.dart';
import '../../common/entities/entities.dart';
import '../../common/interfaces/i_inventory_service.dart';  // ← correct interface
import '../../data/services/inventory_data_service.dart';
import '../../data/services/cache_service.dart';
import '../dtos/inventory_dto.dart';
import 'notification_service.dart';

class InventoryService implements IInventoryDataService {
  final _data = InventoryDataService();

  @override
  Future<List<FoodItem>> fetchInventory() async {  // ← was getInventory
    try {
      final items = await _data.fetchInventory();
      await CacheService.saveInventory(items);
      await LocalNotificationService.scheduleAllFromInventory(items);
      return items;
    } catch (e) {
      debugPrint('[InventoryService] failed: $e — using cache');
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
  Future<bool> deleteItem(String inventoryId) async {  // ← was discardItem
    final success = await _data.deleteItem(inventoryId);
    if (success) {
      await LocalNotificationService.cancelNotification(inventoryId);
      await CacheService.removeItem(inventoryId);
    }
    return success;
  }
}