import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../common/entities/entities.dart';

class CacheService {
  static const _inventoryBoxName = 'inventory_v2'; // was v1
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
    final inventoryKeys = box.keys
        .cast<String>()
        .where((k) => !k.startsWith(_metaKeyPrefix))
        .toList();

    await box.deleteAll(inventoryKeys);
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
    'barcodeRef': item.barcodeRef,
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
    barcodeRef: map['barcodeRef'] as String?,
  );


  //all nottifs stuff
  static const _notificationSettingsKey = 'meta_notification_settings';

  static NotificationSettings loadNotificationSettings() {
    final box = Hive.box<String>(_inventoryBoxName);
    debugPrint('[Cache] All keys: ${box.keys.toList()}'); // ← add this
    final raw = box.get(_notificationSettingsKey);
    debugPrint('[Cache] Settings raw: $raw'); // ← and this
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

// stats stuff ── Consumed / Discarded Counters ─────────────────────────────────────────────

  static const _consumedCountKey  = 'meta_consumed_count';
  static const _discardedCountKey = 'meta_discarded_count';
  static const _fridgeConsumedKey = 'meta_fridge_consumed';
  static const _pantryConsumedKey = 'meta_pantry_consumed';
  static const _freezerConsumedKey = 'meta_freezer_consumed';
  static const _othersConsumedKey = 'meta_others_consumed';
  static const _fridgeDiscardedKey = 'meta_fridge_discarded';
  static const _pantryDiscardedKey = 'meta_pantry_discarded';
  static const _freezerDiscardedKey = 'meta_freezer_discarded';
  static const _othersDiscardedKey = 'meta_others_discarded';

  static const _addedCountKey = 'meta_added_count';
  static String _consumedDayKey(DateTime date) =>
      'meta_consumed_${date.year}_${date.month}_${date.day}';

  static Future<void> incrementAdded() async {
    final box = Hive.box<String>(_inventoryBoxName);

    final current =
        int.tryParse(box.get(_addedCountKey) ?? '0') ?? 0;

    await box.put(_addedCountKey, '${current + 1}');
  }

  static int loadAddedCount() {
    final box = Hive.box<String>(_inventoryBoxName);

    return int.tryParse(
        box.get(_addedCountKey) ?? '0'
    ) ?? 0;
  }

  static Future<void> incrementConsumed() async {
    final box     = Hive.box<String>(_inventoryBoxName);
    final current = int.tryParse(box.get(_consumedCountKey) ?? '0') ?? 0;
    await box.put(_consumedCountKey, '${current + 1}');
    debugPrint('[Cache] Consumed count → ${current + 1}');
    debugPrint(
      '[Cache] Box keys after save = ${box.keys.toList()}',
    );
  }

  static Future<void> incrementDiscarded() async {
    final box     = Hive.box<String>(_inventoryBoxName);
    final current = int.tryParse(box.get(_discardedCountKey) ?? '0') ?? 0;
    await box.put(_discardedCountKey, '${current + 1}');
    debugPrint('[Cache] Discarded count → ${current + 1}');
  }

  static int loadConsumedCount() {
    final box = Hive.box<String>(_inventoryBoxName);
    debugPrint(
      '[Cache] Box keys during load = ${box.keys.toList()}',
    );

    final value =
        int.tryParse(
            box.get(_consumedCountKey) ?? '0'
        ) ?? 0;

    debugPrint(
        '[Cache] Consumed count loaded = $value');

    return value;
  }

  static int loadDiscardedCount() {
    final box = Hive.box<String>(_inventoryBoxName);

    final value =
        int.tryParse(
            box.get(_discardedCountKey) ?? '0'
        ) ?? 0;

    debugPrint(
        '[Cache] discarded count loaded = $value');

    return value;
  }

  static Future<void> incrementConsumedCategory(
      ItemCategory category) async {

    final box = Hive.box<String>(_inventoryBoxName);

    String key;

    switch (category) {
      case ItemCategory.fridge:
        key = _fridgeConsumedKey;
        break;

      case ItemCategory.pantry:
        key = _pantryConsumedKey;
        break;

      case ItemCategory.freezer:
        key = _freezerConsumedKey;
        break;

      default:
        key = _othersConsumedKey;
    }

    final current =
        int.tryParse(box.get(key) ?? '0') ?? 0;

    await box.put(key, '${current + 1}');
  }

  static Future<void> incrementDiscardedCategory(
      ItemCategory category) async {

    final box = Hive.box<String>(_inventoryBoxName);

    String key;

    switch (category) {
      case ItemCategory.fridge:
        key = _fridgeDiscardedKey;
        break;

      case ItemCategory.pantry:
        key = _pantryDiscardedKey;
        break;

      case ItemCategory.freezer:
        key = _freezerDiscardedKey;
        break;

      default:
        key = _othersDiscardedKey;
    }

    final current =
        int.tryParse(box.get(key) ?? '0') ?? 0;

    await box.put(key, '${current + 1}');
  }
  static Map<String, int> loadDiscardedCategories() {
    final box = Hive.box<String>(_inventoryBoxName);

    return {
      'Fridge':
      int.tryParse(
        box.get(_fridgeDiscardedKey) ?? '0',
      ) ?? 0,

      'Pantry':
      int.tryParse(
        box.get(_pantryDiscardedKey) ?? '0',
      ) ?? 0,

      'Freezer':
      int.tryParse(
        box.get(_freezerDiscardedKey) ?? '0',
      ) ?? 0,

      'Others':
      int.tryParse(
        box.get(_othersDiscardedKey) ?? '0',
      ) ?? 0,
    };
  }

  static Future<void> incrementConsumedDay() async {
    final box = Hive.box<String>(_inventoryBoxName);

    final key = _consumedDayKey(DateTime.now());

    final current =
        int.tryParse(box.get(key) ?? '0') ?? 0;

    await box.put(key, '${current + 1}');
  }

  static List<MapEntry<String, int>> loadConsumedTimeline() {
    final box = Hive.box<String>(_inventoryBoxName);

    final now = DateTime.now();

    final result = <MapEntry<String, int>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      final key = _consumedDayKey(date);

      final count =
          int.tryParse(box.get(key) ?? '0') ?? 0;

      result.add(
        MapEntry(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          count,
        ),
      );
    }

    return result;
  }

  //cache stuff
  static Future<void> clearAllData() async {
    final box = Hive.box<String>(_inventoryBoxName);
    await box.clear(); // wipes everything including meta keys
    debugPrint('[Cache] Full cache cleared');
  }





}