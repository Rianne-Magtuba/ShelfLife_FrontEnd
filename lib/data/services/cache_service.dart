//sprint 4

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// Stores inventory items locally on the device using Hive.
///
/// Why cache at all?
/// 1. The app loads instantly — shows cached data while the API call runs.
/// 2. Statistics work offline — no need to re-query the backend.
/// 3. Notifications can be rescheduled on app startup from cache
///    even before the API responds.
class CacheService {
static const _inventoryBoxName = 'inventory_v1';
static bool _initialized = false;

static Future<void> initialize() async {
if (_initialized) return;
await Hive.initFlutter();
await Hive.openBox<String>(_inventoryBoxName);
_initialized = true;
debugPrint('[Cache] Initialized');
}

// ── Save ──────────────────────────────────────────────────────────────────
// Overwrites the entire cache with the freshly fetched list.
// Called after every successful GET /api/inventory.

static Future<void> saveInventory(List<FoodItem> items) async {
final box = Hive.box<String>(_inventoryBoxName);
await box.clear();
for (final item in items) {
// Key = item.id so we can delete individual items without clearing all
await box.put(item.id, jsonEncode(_toMap(item)));
}
debugPrint('[Cache] Saved ${items.length} items');
}

// ── Load ──────────────────────────────────────────────────────────────────
// Returns whatever was last saved — called on app startup.
// Synchronous so it doesn't delay the first frame.

static List<FoodItem> loadInventory() {
final box   = Hive.box<String>(_inventoryBoxName);
final items = <FoodItem>[];

for (final key in box.keys) {
try {
final raw = box.get(key as String);
if (raw != null) {
items.add(_fromMap(jsonDecode(raw) as Map<String, dynamic>));
}
} catch (e) {
// Corrupt entry — skip it, don't crash
debugPrint('[Cache] Skipping corrupt entry $key: $e');
}
}

debugPrint('[Cache] Loaded ${items.length} items from disk');
return items;
}

// ── Remove one ────────────────────────────────────────────────────────────

static Future<void> removeItem(String itemId) async {
await Hive.box<String>(_inventoryBoxName).delete(itemId);
debugPrint('[Cache] Removed $itemId');
}

// ── Clear all ─────────────────────────────────────────────────────────────
// Call on logout so the next user doesn't see stale data.

static Future<void> clearAll() async {
await Hive.box<String>(_inventoryBoxName).clear();
debugPrint('[Cache] Cleared all');
}

// ── Serialization helpers ─────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(FoodItem item) => {
    'id':               item.id,
    'name':             item.name,
    'category':         item.category.name, // stores 'fridge', 'pantry' etc.
    'quantity':         item.quantity,
    'weight':           item.weight,
    'weightUnit':       item.weightUnit,
    'expiryDate':       item.expiryDate.toIso8601String(),
    'dateAdded':        item.dateAdded.toIso8601String(),
    'purchasePrice':    item.purchasePrice,
    'purchaseDate':     item.purchaseDate?.toIso8601String(),
    'notes':            item.notes,
    'consumeWithinDays': item.consumeWithinDays
  }; // <--- ADDED MISSING SEMICOLON

  // <--- ADDED MISSING _fromMap METHOD
  static FoodItem _fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: ItemCategory.values.firstWhere(
            (e) => e.name == map['category'],
        orElse: () => ItemCategory.others,
      ),
      quantity: map['quantity'] as int,
      weight: map['weight'] as String?,
      weightUnit: map['weightUnit'] as String?,
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      purchasePrice: map['purchasePrice'] as double?,
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.parse(map['purchaseDate'] as String)
          : null,
      notes: map['notes'] as String?,
      consumeWithinDays: map['consumeWithinDays'] as int?,
    );
  }

} // <--- ADDED MISSING CLOSING BRACKET FOR CacheService CLASS

