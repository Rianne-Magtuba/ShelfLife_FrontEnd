import '../entities/food_item.dart';
import '../../business/dtos/inventory_dto.dart';

abstract class IInventoryDataService {
  Future<List<FoodItem>> fetchInventory();
  Future<FoodItem> createItem(AddInventoryItemRequest request);
  Future<bool> deleteItem(String inventoryId);
  Future<bool> updateItem(String inventoryId, AddInventoryItemRequest request);
}