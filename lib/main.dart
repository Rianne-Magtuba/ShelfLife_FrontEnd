import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'app/router.dart';
import 'constants/app_theme.dart';
import 'core/data/services/cache_service.dart';
import 'core/data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await LocalNotificationService.initialize();
  await LocalNotificationService.requestPermission();
  await CacheService.initialize();
  final cachedItems = CacheService.loadInventory();
  if (cachedItems.isNotEmpty) {
    await LocalNotificationService.scheduleAllFromInventory(cachedItems);
    debugPrint('[main] Rescheduled notifications from ${cachedItems.length} cached items');
  }
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