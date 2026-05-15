import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'app/router.dart';
import 'constants/app_theme.dart';
import 'data/services/cache_service.dart';
import 'data/services/notification_service.dart';

void main() async {
  // Required before any async work before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data — needed for scheduled notifications
  tz_data.initializeTimeZones();

  // Initialize local notification plugin (Android channel, iOS setup)
  await LocalNotificationService.initialize();

  // Request OS permission for notifications
  // On Android 13+ this shows a permission dialog on first launch
  // On older Android it's granted automatically
  await LocalNotificationService.requestPermission();

  // Initialize Hive local cache
  await CacheService.initialize();

  // Load cached inventory and reschedule notifications on startup.
  // This runs BEFORE runApp so notifications are always current
  // even if the user doesn't open the inventory page.
  final cachedItems = CacheService.loadInventory();
  if (cachedItems.isNotEmpty) {
    await LocalNotificationService.scheduleAllFromInventory(cachedItems);
    debugPrint('[main] Rescheduled notifications from ${cachedItems.length} cached items');
  }

  runApp(
    const ProviderScope(
      child: ShelfLifeApp(),
    ),
  );
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