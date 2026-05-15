//sprint 3

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'cache_service.dart';
import 'notification_service.dart';
import '../mock_data.dart';

/// Shape of what AddInventoryItemRequestDto.cs expects.
/// Maps directly to the C# DTO in Business_Layer/DTOs/InventoryDTO/
class AddInventoryItemRequest {
  final bool isCustomItem;
  final String? barcodeRef;
  final String? customName;
  final String? customCategory;
  final double? customWeightGrams;
  final double? customPrice;
  final int quantity;
  final String quality;
  final String notes;
  final DateTime expirationDate;

  AddInventoryItemRequest({
    required this.isCustomItem,
    this.barcodeRef,
    this.customName,
    this.customCategory,
    this.customWeightGrams,
    this.customPrice,
    required this.quantity,
    required this.quality,
    required this.notes,
    required this.expirationDate,
  });

  Map<String, dynamic> toJson() => {
    'IsCustomItem':      isCustomItem,
    if (barcodeRef      != null) 'BarcodeRef':      barcodeRef,
    if (customName      != null) 'CustomName':      customName,
    if (customCategory  != null) 'CustomCategory':  customCategory,
    if (customWeightGrams != null) 'CustomWeightGrams': customWeightGrams,
    if (customPrice     != null) 'CustomPrice':     customPrice,
    'Quantity':          quantity,
    'Quality':           quality,
    'Notes':             notes,
    // ISO 8601 is what C# DateTime expects
    'ExpirationDate':    expirationDate.toIso8601String(),
  };
}

/// Shape of InventoryItemResponseDto.cs
/// What the backend sends back for each item in the inventory list.
class InventoryItemResponse {
  final String inventoryId;
  final bool isCustomItem;
  final String? barcodeRef;
  final String displayName;
  final String displayCategory;
  final double? weightGrams;
  final double displayPrice;
  final int quantity;
  final String quality;
  final String notes;
  final DateTime expirationDate;
  final DateTime dateRegistered;

  InventoryItemResponse({
    required this.inventoryId,
    required this.isCustomItem,
    this.barcodeRef,
    required this.displayName,
    required this.displayCategory,
    this.weightGrams,
    required this.displayPrice,
    required this.quantity,
    required this.quality,
    required this.notes,
    required this.expirationDate,
    required this.dateRegistered,
  });

  factory InventoryItemResponse.fromJson(Map<String, dynamic> json) {
    return InventoryItemResponse(
      inventoryId:     json['inventoryId']     as String,
      isCustomItem:    json['isCustomItem']     as bool,
      barcodeRef:      json['barcodeRef']       as String?,
      displayName:     json['displayName']      as String,
      displayCategory: json['displayCategory']  as String,
      weightGrams:     (json['weightGrams']     as num?)?.toDouble(),
      displayPrice:    (json['displayPrice']    as num).toDouble(),
      quantity:        json['quantity']         as int,
      quality:         json['quality']          as String,
      notes:           (json['notes']           as String?) ?? '',
      expirationDate:  DateTime.parse(json['expirationDate'] as String),
      dateRegistered:  DateTime.parse(json['dateRegistered'] as String),
    );
  }

  /// Converts backend response into your existing FoodItem model.
  /// This is the bridge between the backend shape and your UI model.
  /// Your pages never see InventoryItemResponse — they only see FoodItem.
  FoodItem toFoodItem() {
    return FoodItem(
      id:           inventoryId,
      name:         displayName,
      category:     _parseCategory(displayCategory),
      quantity:      quantity,
      weight:        weightGrams?.toStringAsFixed(0),
      weightUnit:    weightGrams != null ? 'g' : null,
      expiryDate:    expirationDate,
      dateAdded:     dateRegistered,
      purchasePrice: displayPrice > 0 ? displayPrice : null,
      notes:         notes.isNotEmpty ? notes : null,
    );
  }

  static ItemCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fridge':  return ItemCategory.fridge;
      case 'pantry':  return ItemCategory.pantry;
      case 'freezer': return ItemCategory.freezer;
      default:        return ItemCategory.others;
    }
  }
}

// ─── Interface ────────────────────────────────────────────────────────────────

abstract class IInventoryService {
  Future<List<FoodItem>> getInventory();
  Future<FoodItem> addItem(AddInventoryItemRequest request);
  Future<bool> discardItem(String inventoryId);
}

// ─── MOCK ─────────────────────────────────────────────────────────────────────

class MockInventoryService implements IInventoryService {
  // Starts with your existing mock data so all pages still work
  //final List<FoodItem> _items = List.from(MockDataStore.items);
  // Replace line 141 with this:
  final List<FoodItem> _items = [];

  @override
  Future<List<FoodItem>> getInventory() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Mimic what the real service does after fetching:
    // save to cache and schedule notifications
    await CacheService.saveInventory(_items);
    await LocalNotificationService.scheduleAllFromInventory(_items);

    debugPrint('[InventoryService] Mock returned ${_items.length} items');
    return List.from(_items);
  }

  @override
  Future<FoodItem> addItem(AddInventoryItemRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final newItem = FoodItem(
      id:           DateTime.now().millisecondsSinceEpoch.toString(),
      name:         request.customName ?? 'Unknown',
      category:     InventoryItemResponse._parseCategory(
          request.customCategory ?? 'Others'),
      quantity:      request.quantity,
      weight:        request.customWeightGrams?.toStringAsFixed(0),
      weightUnit:    request.customWeightGrams != null ? 'g' : null,
      expiryDate:    request.expirationDate,
      dateAdded:     DateTime.now(),
      purchasePrice: request.customPrice,
      notes:         request.notes.isNotEmpty ? request.notes : null,
    );

    _items.add(newItem);

    // Schedule a notification for the new item immediately
    await LocalNotificationService.scheduleExpiryNotification(newItem);

    debugPrint('[InventoryService] Mock added: ${newItem.name}');
    return newItem;
  }

  @override
  Future<bool> discardItem(String inventoryId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _items.removeWhere((i) => i.id == inventoryId);

    // Cancel the scheduled notification for this item
    await LocalNotificationService.cancelNotification(inventoryId);

    debugPrint('[InventoryService] Mock discarded: $inventoryId');
    return true;
  }
}

// ─── REAL ─────────────────────────────────────────────────────────────────────

class InventoryService implements IInventoryService {
  static const _storage = FlutterSecureStorage();

  // Helper to get the user ID if needed (though usually handled by JWT)
  Future<String> _getUserId() async {
    final id = await _storage.read(key: 'user_id');
    if (id == null) throw Exception('Not logged in');
    return id;
  }

  @override
  Future<List<FoodItem>> getInventory() async {
    // The backend uses the JWT token (via ApiClient) to identify the user.
    final response = await ApiClient.get('/api/inventory');

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List<dynamic>;

      final items = jsonList
          .map((j) => InventoryItemResponse.fromJson(j as Map<String, dynamic>).toFoodItem())
          .toList();

      return items;
    } else {
      throw Exception('Failed to load inventory: ${response.statusCode}');
    }
  }

  @override
  Future<FoodItem> addItem(AddInventoryItemRequest request) async {
    final response = await ApiClient.post(
      '/api/inventory',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return InventoryItemResponse.fromJson(jsonData).toFoodItem();
    } else {
      throw Exception('Failed to add item: ${response.body}');
    }
  }

  @override
  Future<bool> discardItem(String inventoryId) async {
    // Correctly point to the specific item ID in the URL
    final response = await ApiClient.delete('/api/inventory/$inventoryId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      debugPrint('Discard failed: ${response.body}');
      return false;
    }
  }
}