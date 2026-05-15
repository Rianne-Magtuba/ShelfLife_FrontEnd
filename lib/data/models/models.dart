import 'package:flutter/material.dart';

enum ItemCategory { fridge, pantry, freezer, others }

enum ItemStatus { fresh, expiringSoon, expired }

enum ExpiryMode { exactDate, afterManufacturing }

extension ItemCategoryExt on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.fridge:
        return 'Fridge';
      case ItemCategory.pantry:
        return 'Pantry';
      case ItemCategory.freezer:
        return 'Freezer';
      case ItemCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.fridge:
        return Icons.kitchen_outlined;
      case ItemCategory.pantry:
        return Icons.shelves;
      case ItemCategory.freezer:
        return Icons.ac_unit_outlined;
      case ItemCategory.others:
        return Icons.category_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ItemCategory.fridge:
        return const Color(0xFF1565C0);
      case ItemCategory.pantry:
        return const Color(0xFF6B4A2B);
      case ItemCategory.freezer:
        return const Color(0xFF0097A7);
      case ItemCategory.others:
        return const Color(0xFF6A1B9A);
    }
  }
}

extension ItemStatusExt on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.fresh:
        return 'Fresh';
      case ItemStatus.expiringSoon:
        return 'Expiring Soon';
      case ItemStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case ItemStatus.fresh:
        return const Color(0xFF2E7D32);
      case ItemStatus.expiringSoon:
        return const Color(0xFFF57F17);
      case ItemStatus.expired:
        return const Color(0xFFC62828);
    }
  }

  Color get bgColor {
    switch (this) {
      case ItemStatus.fresh:
        return const Color(0xFFE8F5E9);
      case ItemStatus.expiringSoon:
        return const Color(0xFFFFF8E1);
      case ItemStatus.expired:
        return const Color(0xFFFFEBEE);
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
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    if (daysLeft < 0) return ItemStatus.expired;
    if (daysLeft <= 3) return ItemStatus.expiringSoon;
    return ItemStatus.fresh;
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  FoodItem copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    int? quantity,
    String? weight,
    String? weightUnit,
    DateTime? expiryDate,
    DateTime? dateAdded,
    String? imagePath,
    String? notes,
    double? purchasePrice,
    DateTime? purchaseDate,
    int? consumeWithinDays,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      expiryDate: expiryDate ?? this.expiryDate,
      dateAdded: dateAdded ?? this.dateAdded,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      consumeWithinDays: consumeWithinDays ?? this.consumeWithinDays,
    );
  }
}

class AppNotification {
  final String id;
  final String itemId;
  final String itemName;
  final String message;
  final String subtitle;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final int? daysLeft;

  AppNotification({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.message,
    required this.subtitle,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.daysLeft,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      itemId: itemId,
      itemName: itemName,
      message: message,
      subtitle: subtitle,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      daysLeft: daysLeft,
    );
  }
}

enum NotificationType { expired, expiringSoon, consumed, added }

extension NotificationTypeExt on NotificationType {
  Color get color {
    switch (this) {
      case NotificationType.expired:
        return const Color(0xFFC62828);
      case NotificationType.expiringSoon:
        return const Color(0xFFF57F17);
      case NotificationType.consumed:
        return const Color(0xFF2E7D32);
      case NotificationType.added:
        return const Color(0xFF1565C0);
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.expired:
        return Icons.warning_amber_outlined;
      case NotificationType.expiringSoon:
        return Icons.notifications_outlined;
      case NotificationType.consumed:
        return Icons.check_circle_outline;
      case NotificationType.added:
        return Icons.add_circle_outline;
    }
  }
}

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarPath;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarPath,
  });

  String get initials {
    final name = displayName ?? username;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;
}

class NotificationSettings {
  final bool enabled;
  final int alertLeadDays;
  final TimeOfDay dailyReminderTime;
  final String frequency; // 'once', 'daily', 'realtime'

  NotificationSettings({
    required this.enabled,
    required this.alertLeadDays,
    required this.dailyReminderTime,
    required this.frequency,
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? alertLeadDays,
    TimeOfDay? dailyReminderTime,
    String? frequency,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      alertLeadDays: alertLeadDays ?? this.alertLeadDays,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      frequency: frequency ?? this.frequency,
    );
  }
}
