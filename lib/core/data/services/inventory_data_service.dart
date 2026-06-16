import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../../common/entities/entities.dart';
import '../../common/interfaces/i_inventory_service.dart';
import '../../business/dtos/inventory_dto.dart';
import 'api_client.dart';
import 'cache_service.dart';

class InventoryDataService implements IInventoryDataService {

  @override
  Future<List<FoodItem>> fetchInventory() async {
    final response = await ApiClient.get('/api/inventory/pantry');

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((j) => InventoryItemResponse
          .fromJson(j as Map<String, dynamic>)
          .toFoodItem())
          .toList();
    }

    debugPrint('[InventoryDataService] ${response.statusCode}');
    throw Exception(ApiClient.parseError(response, 'Failed to fetch inventory.'));
  }

  @override
  Future<FoodItem> createItem(AddInventoryItemRequest request) async {
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

  @override
  Future<bool> updateItem(
      String inventoryId,
      AddInventoryItemRequest request,
      ) async {
    final response = await ApiClient.put(
      '/api/inventory/$inventoryId',
      request.toJson(),
    );

    return response.statusCode >= 200 &&
        response.statusCode < 300;
  }

  @override
  Future<bool> deleteItem(String inventoryId) async {
    final response =
    await ApiClient.delete(
      '/api/inventory/$inventoryId',
    );

    debugPrint(
      '[DELETE] Status = ${response.statusCode}',
    );

    debugPrint(
      '[DELETE] Body = ${response.body}',
    );

    return response.statusCode == 200 ||
        response.statusCode == 204;
  }

  static ItemCategory _parseCategory(String c) {
    switch (c.toLowerCase()) {
      case 'fridge':  return ItemCategory.fridge;
      case 'pantry':  return ItemCategory.pantry;
      case 'freezer': return ItemCategory.freezer;
      default:        return ItemCategory.others;
    }
  }

  @override
  Future<bool> consumeItem(String inventoryId) async {
    final response = await ApiClient.delete(
      '/api/inventory/$inventoryId/consume',
    );
    return response.statusCode == 200;
  }

  // ── Cache helpers ───────────────────────────────────────────────────────

  @override
  List<FoodItem> loadInventory() => CacheService.loadInventory();

  @override
  Future<void> saveInventory(List<FoodItem> items) =>
      CacheService.saveInventory(items);

  @override
  Future<void> removeItem(String itemId) => CacheService.removeItem(itemId);

  // ── Consumed / discarded counters ───────────────────────────────────────

  @override
  int loadConsumedCount() => CacheService.loadConsumedCount();

  @override
  int loadDiscardedCount() => CacheService.loadDiscardedCount();

  @override
  Future<void> incrementConsumed() => CacheService.incrementConsumed();

  @override
  Future<void> incrementDiscarded() => CacheService.incrementDiscarded();



  // ── Notification settings ───────────────────────────────────────────────

  @override
  NotificationSettings loadNotificationSettings() =>
      CacheService.loadNotificationSettings();

  @override
  Future<void> saveNotificationSettings(NotificationSettings settings) =>
      CacheService.saveNotificationSettings(settings);
}