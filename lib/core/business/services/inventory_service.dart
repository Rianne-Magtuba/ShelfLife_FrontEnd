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
Future<FoodItem> createItem(AddInventoryItemRequest request) async {
    final item = await _data.createItem(request);
    await LocalNotificationService.scheduleExpiryNotification(item);
    return item;
  
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

  @override
  Future<bool> updateItem(
    String inventoryId,
    AddInventoryItemRequest request,
    ) =>
    _data.updateItem(
      inventoryId,
      request,
    );
}