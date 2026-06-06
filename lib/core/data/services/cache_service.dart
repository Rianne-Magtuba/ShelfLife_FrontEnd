import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../common/entities/entities.dart';

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


  static Future<void> saveInventory(List<FoodItem> items) async {
    final box = Hive.box<String>(_inventoryBoxName);
    await box.clear();
    for (final item in items) {
      await box.put(item.id, jsonEncode(_toMap(item)));
    }
    debugPrint('[Cache] Saved ${items.length} items');
  }

  static const _metaKeyPrefix = 'meta_';
  static List<FoodItem> loadInventory() {

    final box   = Hive.box<String>(_inventoryBoxName);
    final items = <FoodItem>[];
    for (final key in box.keys) {
      final keyStr = key as String;
      if (keyStr.startsWith(_metaKeyPrefix)) continue; // ← skip meta entries
      try {
        final raw = box.get(keyStr);
        if (raw != null) items.add(_fromMap(jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('[Cache] Skipping corrupt entry $keyStr: $e');
      }
    }
    debugPrint('[Cache] Loaded ${items.length} items from disk');
    return items;
  }

  static Future<void> removeItem(String itemId) async {
    await Hive.box<String>(_inventoryBoxName).delete(itemId);
    debugPrint('[Cache] Removed $itemId');
  }

  static Future<void> clearAll() async {
    final box = Hive.box<String>(_inventoryBoxName);
    final inventoryKeys = box.keys
        .cast<String>()
        .where((k) => !k.startsWith(_metaKeyPrefix))
        .toList();
    await box.deleteAll(inventoryKeys);
    debugPrint('[Cache] Cleared all inventory items');
  }

  static Map<String, dynamic> _toMap(FoodItem item) => {
    'id':               item.id,
    'name':             item.name,
    'category':         item.category.name,
    'quantity':         item.quantity,
    'weight':           item.weight,
    'weightUnit':       item.weightUnit,
    'expiryDate':       item.expiryDate.toIso8601String(),
    'dateAdded':        item.dateAdded.toIso8601String(),
    'purchasePrice':    item.purchasePrice,
    'purchaseDate':     item.purchaseDate?.toIso8601String(),
    'notes':            item.notes,
    'consumeWithinDays': item.consumeWithinDays,
  };

  static FoodItem _fromMap(Map<String, dynamic> map) => FoodItem(
    id:       map['id']   as String,
    name:     map['name'] as String,
    category: ItemCategory.values.firstWhere(
          (e) => e.name == map['category'],
      orElse: () => ItemCategory.others,
    ),
    quantity:         map['quantity']         as int,
    weight:           map['weight']           as String?,
    weightUnit:       map['weightUnit']       as String?,
    expiryDate:       DateTime.parse(map['expiryDate'] as String),
    dateAdded:        DateTime.parse(map['dateAdded']  as String),
    purchasePrice:    map['purchasePrice']    as double?,
    purchaseDate:     map['purchaseDate'] != null
        ? DateTime.parse(map['purchaseDate'] as String) : null,
    notes:            map['notes']            as String?,
    consumeWithinDays: map['consumeWithinDays'] as int?,
  );

  static const _notificationSettingsKey = 'meta_notification_settings';

  static NotificationSettings loadNotificationSettings() {
    final box = Hive.box<String>(_inventoryBoxName);
    final raw = box.get(_notificationSettingsKey);
    if (raw == null) {
      return NotificationSettings(
        enabled: true,
        alertLeadDays: 3,
        dailyReminderTime: TimeOfDay(hour: 8, minute: 0),
        frequency: 'daily',
      );
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationSettings(
        enabled:            map['enabled']         as bool,
        alertLeadDays:      map['alertLeadDays']   as int,
        dailyReminderTime:  TimeOfDay(
          hour:   map['reminderHour']   as int,
          minute: map['reminderMinute'] as int,
        ),
        frequency:          map['frequency']       as String,
      );
    } catch (e) {
      debugPrint('[Cache] Failed to parse notification settings: $e');
      return NotificationSettings(
        enabled: true,
        alertLeadDays: 3,
        dailyReminderTime: TimeOfDay(hour: 8, minute: 0),
        frequency: 'daily',
      );
    }
  }

  static Future<void> saveNotificationSettings(
      NotificationSettings settings) async {
    final box = Hive.box<String>(_inventoryBoxName);
    await box.put(
      _notificationSettingsKey,
      jsonEncode({
        'enabled':       settings.enabled,
        'alertLeadDays': settings.alertLeadDays,
        'reminderHour':  settings.dailyReminderTime.hour,
        'reminderMinute':settings.dailyReminderTime.minute,
        'frequency':     settings.frequency,
      }),
    );
    debugPrint('[Cache] Saved notification settings');
  }

// ── Consumed / Discarded Counters ─────────────────────────────────────────────

  static const _consumedCountKey  = 'meta_consumed_count';
  static const _discardedCountKey = 'meta_discarded_count';

  static Future<void> incrementConsumed() async {
    final box     = Hive.box<String>(_inventoryBoxName);
    final current = int.tryParse(box.get(_consumedCountKey) ?? '0') ?? 0;
    await box.put(_consumedCountKey, '${current + 1}');
    debugPrint('[Cache] Consumed count → ${current + 1}');
  }

  static Future<void> incrementDiscarded() async {
    final box     = Hive.box<String>(_inventoryBoxName);
    final current = int.tryParse(box.get(_discardedCountKey) ?? '0') ?? 0;
    await box.put(_discardedCountKey, '${current + 1}');
    debugPrint('[Cache] Discarded count → ${current + 1}');
  }

  static int loadConsumedCount() {
    final box = Hive.box<String>(_inventoryBoxName);
    return int.tryParse(box.get(_consumedCountKey) ?? '0') ?? 0;
  }

  static int loadDiscardedCount() {
    final box = Hive.box<String>(_inventoryBoxName);
    return int.tryParse(box.get(_discardedCountKey) ?? '0') ?? 0;
  }

}