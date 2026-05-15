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
    return InventoryItemResponse(
      inventoryId:     json['inventoryId']    as String,
      isCustomItem:    json['isCustomItem']    as bool,
      barcodeRef:      json['barcodeRef']      as String?,
      displayName:     json['displayName']     as String,
      displayCategory: json['displayCategory'] as String,
      weightGrams:     (json['weightGrams']    as num?)?.toDouble(),
      displayPrice:    (json['displayPrice']   as num).toDouble(),
      quantity:        json['quantity']        as int,
      quality:         json['quality']         as String,
      notes:           (json['notes']          as String?) ?? '',
      expirationDate:  DateTime.parse(json['expirationDate'] as String),
      dateRegistered:  DateTime.parse(json['dateRegistered'] as String),
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