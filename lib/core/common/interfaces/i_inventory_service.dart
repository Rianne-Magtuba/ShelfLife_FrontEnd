import '../entities/food_item.dart';
import '../../business/dtos/inventory_dto.dart';

abstract class IInventoryService {
  Future<List<FoodItem>> getInventory();
  Future<FoodItem> addItem(AddInventoryItemRequest request);
  Future<bool> discardItem(String inventoryId);
}