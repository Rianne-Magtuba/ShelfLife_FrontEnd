import 'package:flutter/material.dart';

export 'food_item.dart';

enum ItemCategory { fridge, pantry, freezer, others }
enum ItemStatus { fresh, expiringSoon, expired }
enum ExpiryMode { exactDate, afterManufacturing }

extension ItemCategoryExt on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.fridge:   return 'Fridge';
      case ItemCategory.pantry:   return 'Pantry';
      case ItemCategory.freezer:  return 'Freezer';
      case ItemCategory.others:   return 'Others';
    }
  }
  IconData get icon {
    switch (this) {
      case ItemCategory.fridge:   return Icons.kitchen_outlined;
      case ItemCategory.pantry:   return Icons.shelves;
      case ItemCategory.freezer:  return Icons.ac_unit_outlined;
      case ItemCategory.others:   return Icons.category_outlined;
    }
  }
  Color get color {
    switch (this) {
      case ItemCategory.fridge:   return const Color(0xFF1565C0);
      case ItemCategory.pantry:   return const Color(0xFF6B4A2B);
      case ItemCategory.freezer:  return const Color(0xFF0097A7);
      case ItemCategory.others:   return const Color(0xFF6A1B9A);
    }
  }
}

extension ItemStatusExt on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.fresh:         return 'Fresh';
      case ItemStatus.expiringSoon:  return 'Expiring Soon';
      case ItemStatus.expired:       return 'Expired';
    }
  }
  Color get color {
    switch (this) {
      case ItemStatus.fresh:         return const Color(0xFF2E7D32);
      case ItemStatus.expiringSoon:  return const Color(0xFFF57F17);
      case ItemStatus.expired:       return const Color(0xFFC62828);
    }
  }
  Color get bgColor {
    switch (this) {
      case ItemStatus.fresh:         return const Color(0xFFE8F5E9);
      case ItemStatus.expiringSoon:  return const Color(0xFFFFF8E1);
      case ItemStatus.expired:       return const Color(0xFFFFEBEE);
    }
  }
}

class FoodItem {
  final String id;
  final String name;
  final ItemCategory category;
  final int quantity;
  final String? weight;
  final String? weightUnit;
  final DateTime expiryDate;
  final DateTime dateAdded;
  final String? imagePath;
  final String? notes;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final int? consumeWithinDays;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    this.weight,
    this.weightUnit,
    required this.expiryDate,
    required this.dateAdded,
    this.imagePath,
    this.notes,
    this.purchasePrice,
    this.purchaseDate,
    this.consumeWithinDays,
  });

  ItemStatus get status {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return ItemStatus.expired;
    if (daysLeft <= 3) return ItemStatus.expiringSoon;
    return ItemStatus.fresh;
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  FoodItem copyWith({
    String? id, String? name, ItemCategory? category, int? quantity,
    String? weight, String? weightUnit, DateTime? expiryDate,
    DateTime? dateAdded, String? imagePath, String? notes,
    double? purchasePrice, DateTime? purchaseDate, int? consumeWithinDays,
  }) => FoodItem(
    id: id ?? this.id, name: name ?? this.name,
    category: category ?? this.category, quantity: quantity ?? this.quantity,
    weight: weight ?? this.weight, weightUnit: weightUnit ?? this.weightUnit,
    expiryDate: expiryDate ?? this.expiryDate, dateAdded: dateAdded ?? this.dateAdded,
    imagePath: imagePath ?? this.imagePath, notes: notes ?? this.notes,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    consumeWithinDays: consumeWithinDays ?? this.consumeWithinDays,
  );
}