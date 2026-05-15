import 'package:flutter/material.dart';

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
    required this.id, required this.itemId, required this.itemName,
    required this.message, required this.subtitle, required this.timestamp,
    required this.isRead, required this.type, this.daysLeft,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, itemId: itemId, itemName: itemName, message: message,
    subtitle: subtitle, timestamp: timestamp, isRead: isRead ?? this.isRead,
    type: type, daysLeft: daysLeft,
  );
}

enum NotificationType { expired, expiringSoon, consumed, added }

extension NotificationTypeExt on NotificationType {
  Color get color {
    switch (this) {
      case NotificationType.expired:      return const Color(0xFFC62828);
      case NotificationType.expiringSoon: return const Color(0xFFF57F17);
      case NotificationType.consumed:     return const Color(0xFF2E7D32);
      case NotificationType.added:        return const Color(0xFF1565C0);
    }
  }
  IconData get icon {
    switch (this) {
      case NotificationType.expired:      return Icons.warning_amber_outlined;
      case NotificationType.expiringSoon: return Icons.notifications_outlined;
      case NotificationType.consumed:     return Icons.check_circle_outline;
      case NotificationType.added:        return Icons.add_circle_outline;
    }
  }
}

class NotificationSettings {
  final bool enabled;
  final int alertLeadDays;
  final TimeOfDay dailyReminderTime;
  final String frequency;

  NotificationSettings({
    required this.enabled, required this.alertLeadDays,
    required this.dailyReminderTime, required this.frequency,
  });

  NotificationSettings copyWith({
    bool? enabled, int? alertLeadDays,
    TimeOfDay? dailyReminderTime, String? frequency,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    alertLeadDays: alertLeadDays ?? this.alertLeadDays,
    dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    frequency: frequency ?? this.frequency,
  );
}