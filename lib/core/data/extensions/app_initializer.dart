import 'package:flutter/foundation.dart';
import '../services/cache_service.dart';
import '../../business/services/notification_service.dart';

/// Mirrors the role of DependencyInjectionExtensions.cs —
/// one place that bootstraps all infrastructure before the app runs.
/// main() calls this once, knows nothing about Hive or notification internals.
class AppInitializer {
  static Future<void> initialize() async {
    await CacheService.initialize();
    await LocalNotificationService.initialize();
    await LocalNotificationService.requestPermission();

    final cachedItems = CacheService.loadInventory();
    if (cachedItems.isNotEmpty) {
      try {
        await LocalNotificationService.scheduleAllFromInventory(cachedItems);
        debugPrint('[AppInitializer] Rescheduled ${cachedItems.length} cached items');
      } catch (e) {
        debugPrint('[AppInitializer] Notification scheduling failed: $e');
      }
    }
  }
}