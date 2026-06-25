import '../entities/food_item.dart';
import '../../business/dtos/inventory_dto.dart';
import '../entities/notification.dart';

abstract class IInventoryDataService {
  // ── Inventory CRUD ──────────────────────────────────────────────────────
  Future<List<FoodItem>> fetchInventory();
  Future<FoodItem>       createItem(AddInventoryItemRequest request);
  Future<bool>           updateItem(String inventoryId, AddInventoryItemRequest request);
  Future<bool>           deleteItem(String inventoryId);

  // ── Cache helpers ───────────────────────────────────────────────────────
  List<FoodItem>       loadInventory();
  Future<void>         saveInventory(List<FoodItem> items);
  Future<void>         removeItem(String itemId);

  // ── Consumed / discarded counters ───────────────────────────────────────
  int          loadConsumedCount();
  int          loadDiscardedCount();
  Future<void> incrementConsumed();
  Future<void> incrementDiscarded();
  Future<bool> consumeItem(String inventoryId);

}