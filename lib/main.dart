import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'app/router.dart';
import 'constants/app_theme.dart';
import 'core/data/services/api_client.dart';
import 'core/data/services/cache_service.dart';
import 'core/business/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.initialize();
  await LocalNotificationService.initialize(); // already calls requestPermission internally



  final settings = CacheService.loadNotificationSettings();
  final cachedItems = CacheService.loadInventory();

  if (cachedItems.isNotEmpty && settings.enabled) {
    try {
      await LocalNotificationService.scheduleAllFromInventory(
        cachedItems,
        daysBeforeExpiry: settings.alertLeadDays,
        reminderHour:     settings.dailyReminderTime.hour,
        reminderMinute:   settings.dailyReminderTime.minute,
        frequency:        settings.frequency,
      );
      debugPrint('[main] Scheduled ${cachedItems.length} items');
    } catch (e) {
      debugPrint('[main] WARNING: $e');
    }
  }

  // ← Add this
  ApiClient.onUnauthorized = () async {
    await ApiClient.clearAll();           // clear expired token
    appRouter.go(AppRoutes.login);        // redirect to login
  };

  //await LocalNotificationService.debugPending();
  // await Future.delayed(
  //   const Duration(seconds: 10),
  // );
  //
  // debugPrint('AFTER 10 SECONDS');

  // await LocalNotificationService.debugPending();
  // await LocalNotificationService.debugShowImmediate();

  runApp(const ProviderScope(child: ShelfLifeApp()));
}

class ShelfLifeApp extends StatelessWidget {
  const ShelfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShelfLife',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}