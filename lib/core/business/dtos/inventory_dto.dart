import 'package:flutter/foundation.dart';
import '../../../core/common/entities/food_item.dart';

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
    'IsCustomItem':    isCustomItem,
    if (barcodeRef        != null) 'BarcodeRef':       barcodeRef,
    if (customName        != null) 'CustomName':       customName,
    if (customCategory    != null) 'CustomCategory':   customCategory,
    if (customWeightGrams != null) 'CustomWeightGrams': customWeightGrams,
    if (customPrice       != null) 'CustomPrice':      customPrice,
    'Quantity':        quantity,
    'Quality':         quality,
    'Notes':           notes,
    'ExpirationDate': expirationDate.toUtc().toIso8601String().replaceAll(RegExp(r'\.\d{3}'), ''),
  };
}

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
    debugPrint('[InventoryItemResponse.fromJson] Raw JSON: $json');
    debugPrint('[InventoryItemResponse.fromJson] JSON keys: ${json.keys.toList()}');

    // Map response fields (backend may return CustomName or displayName, etc.)
    final displayName = (json['displayName'] ?? json['CustomName']) as String?;
    final displayCategory = (json['displayCategory'] ?? json['CustomCategory']) as String?;
    final weightGrams = (json['weightGrams'] ?? json['CustomWeightGrams']) as num?;
    final displayPrice = ((json['displayPrice'] ?? json['CustomPrice']) as num?)?.toDouble() ?? 0.0;
    final expirationDateStr = json['ExpirationDate'] ?? json['expirationDate'];
    final parsedId = (json['inventoryId'] ?? json['InventoryId']) as String?;
    if (parsedId == null || parsedId.isEmpty) {
  throw Exception('Invalid inventory response: inventoryId is missing. Keys found: ${json.keys.toList()}');
}
    debugPrint('[InventoryItemResponse.fromJson] displayName=$displayName, displayCategory=$displayCategory, expirationDateStr=$expirationDateStr');

    if (displayName == null || displayName.isEmpty) {
      throw Exception('Invalid inventory response: displayName is required. Available keys: ${json.keys.toList()}');
    }
    if (displayCategory == null || displayCategory.isEmpty) {
      throw Exception('Invalid inventory response: displayCategory is required. Available keys: ${json.keys.toList()}');
    }
    if (expirationDateStr == null) {
      throw Exception('Invalid inventory response: expirationDate is required. Available keys: ${json.keys.toList()}');
    }

    return InventoryItemResponse(
      inventoryId:   parsedId,
      isCustomItem:    json['isCustomItem'] as bool? ?? json['IsCustomItem'] as bool? ?? true,
      barcodeRef:      json['barcodeRef'] as String? ?? json['BarcodeRef'] as String?,
      displayName:     displayName,
      displayCategory: displayCategory,
      weightGrams:     weightGrams?.toDouble(),
      displayPrice:    displayPrice,
      quantity:        json['quantity'] as int? ?? json['Quantity'] as int? ?? 0,
      quality:         json['quality'] as String? ?? json['Quality'] as String? ?? 'Good',
      notes:           (json['notes'] as String? ?? json['Notes'] as String?) ?? '',
      expirationDate:  DateTime.parse(expirationDateStr as String),
      dateRegistered:  DateTime.parse(json['dateRegistered'] as String? ?? json['DateRegistered'] as String? ?? DateTime.now().toUtc().toIso8601String()),
    );
  }

  FoodItem toFoodItem() => FoodItem(
    id:           inventoryId,
    name:         displayName,
    category:     _parseCategory(displayCategory),
    quantity:     quantity,
    weight:       weightGrams?.toStringAsFixed(0),
    weightUnit:   weightGrams != null ? 'g' : null,
    expiryDate:   expirationDate,
    dateAdded:    dateRegistered,
    purchasePrice: displayPrice > 0 ? displayPrice : null,
    notes:        notes.isNotEmpty ? notes : null,
  );

  static ItemCategory _parseCategory(String c) {
    switch (c.toLowerCase()) {
      case 'fridge':  return ItemCategory.fridge;
      case 'pantry':  return ItemCategory.pantry;
      case 'freezer': return ItemCategory.freezer;
      default:        return ItemCategory.others;
    }
  }
}