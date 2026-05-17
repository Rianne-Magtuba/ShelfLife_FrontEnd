import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../common/entities/entities.dart';
import '../../common/interfaces/i_inventory_service.dart';
import '../../business/dtos/inventory_dto.dart';
import 'api_client.dart';

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

      if (json.containsKey('message') && json.length == 1) {
        return FoodItem(
          id:            'temp_${DateTime.now().millisecondsSinceEpoch}',
          name:          request.customName ?? 'Item',
          category:      _parseCategory(request.customCategory ?? 'Others'),
          quantity:      request.quantity,
          weight:        request.customWeightGrams?.toStringAsFixed(0),
          weightUnit:    request.customWeightGrams != null ? 'g' : null,
          expiryDate:    request.expirationDate,
          dateAdded:     DateTime.now(),
          purchasePrice: request.customPrice,
          notes:         request.notes.isNotEmpty ? request.notes : null,
        );
      }

      return InventoryItemResponse.fromJson(json).toFoodItem();
    }

    throw Exception(ApiClient.parseError(response, 'Failed to add item.'));
  }

  @override
  Future<bool> deleteItem(String inventoryId) async {
    final response = await ApiClient.delete('/api/inventory/$inventoryId');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  static ItemCategory _parseCategory(String c) {
    switch (c.toLowerCase()) {
      case 'fridge':  return ItemCategory.fridge;
      case 'pantry':  return ItemCategory.pantry;
      case 'freezer': return ItemCategory.freezer;
      default:        return ItemCategory.others;
    }
  }
}