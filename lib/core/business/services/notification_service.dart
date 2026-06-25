import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../common/entities/entities.dart';  // ← updated import

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId   = 'shelflife_expiry';
  static const _channelName = 'Expiry Alerts';
  static const _channelDesc = 'Notifications for food items nearing expiry';



  // ── Initialize ────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const androidSettings = AndroidInitializationSettings('@drawable/applogo');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    debugPrint('STEP 1');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notifications] Tapped: ${details.payload}');
      },
    );

    // ← Explicitly create the channel with HIGH importance
    const channel = AndroidNotificationChannel(
      'shelflife_expiry',
      'Expiry Alerts',
      description: 'Notifications for food items nearing expiry',
      importance: Importance.high,    // ← this is what enables heads-up banners
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // In LocalNotificationService.initialize(), after creating shelflife_expiry channel:

    const persistentChannel = AndroidNotificationChannel(
      'shelflife_persistent',
      'ShelfLife Monitoring',
      description: 'Persistent inventory monitoring',
      importance: Importance.high,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(persistentChannel);

    debugPrint('STEP 2');
    await requestPermission();
    debugPrint('STEP 3');
    _initialized = true;
    debugPrint('[Notifications] Initialized');


    debugPrint(
      '[Notifications] Local timezone = ${tz.local.name}',
    );
  }
  // ── Request permission ────────────────────────────────────────────────────
  // THIS was the broken part — generics must be inline, not on a new line

 static Future<bool> requestPermission() async {
   debugPrint('[Notifications] requestPermission() called');
    bool granted = false;

    // Android
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      // 1. Request standard notification permission (Android 13+)
      final result = await android.requestNotificationsPermission();
      granted = result ?? false;

      // 2. Request exact alarm permission (Android 12/14+)
      // THIS IS CRITICAL TO PREVENT THE CRASH
      await android.requestExactAlarmsPermission();

      final canSchedule =
      await android.canScheduleExactNotifications();

      debugPrint(
        '[Notifications] Exact alarm permission: $canSchedule',
      );
    }

    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    debugPrint('[Notifications] Permission granted: $granted');
   debugPrint('[Notifications] requestPermission() finished');
    return granted;


  }


  // ── Schedule for one item ─────────────────────────────────────────────────
  static Future<void> scheduleExpiryNotification(
      FoodItem item, {
        int daysBeforeExpiry = 3,
        int reminderHour = 8,
        int reminderMinute = 0,
        String frequency = 'daily',
      }) async {
    final location = tz.local;
    final now = tz.TZDateTime.now(location);

    // ── Build the message based on days left ────────────────────────────────
    final days = item.daysUntilExpiry;

    String title;
    String body;

    if (days <= 0) {
      title = '🚨 Expired — ${item.name}';
      body  = '${item.name} in your ${item.category.label} has already expired. '
          'Consider discarding it.';
    } else if (days == 1) {
      title = '⚠️ Expiring Tomorrow — ${item.name}';
      body  = '${item.name} expires tomorrow! Use it today before it goes to waste.';
    } else if (days <= 3) {
      title = '⏰ Expiring Soon — ${item.name}';
      body  = '${item.name} expires in $days days. '
          'Check your ${item.category.label} soon.';
    } else {
      title = '📦 Heads Up — ${item.name}';
      body  = '${item.name} expires in $days days. '
          'Plan to use it from your ${item.category.label}.';
    }

    // ── Build scheduled time based on frequency ────────────────────────────
    tz.TZDateTime scheduledDate;

    if (frequency == 'once') {
      final alertDay = item.expiryDate.subtract(Duration(days: daysBeforeExpiry));

      scheduledDate = tz.TZDateTime(
        location,
        alertDay.year,
        alertDay.month,
        alertDay.day,
        reminderHour,
        reminderMinute,
      );

      // ← add this: if alert day passed but item not yet expired, fire today
      if (scheduledDate.isBefore(now) && item.daysUntilExpiry >= 0) {
        scheduledDate = tz.TZDateTime(
          location,
          now.year,
          now.month,
          now.day,
          reminderHour,
          reminderMinute,
        );
      }
    } else if (frequency == 'daily') {
      // Fire today at reminder time if within the lead window,
      // otherwise fire on the first day of the alert window
      final alertStart = item.expiryDate.subtract(
        Duration(days: daysBeforeExpiry),
      );
      final alertStartTZ = tz.TZDateTime(
        location,
        alertStart.year,
        alertStart.month,
        alertStart.day,
        reminderHour,
        reminderMinute,
      );
      // If we're already inside the alert window, fire today at reminder time
      scheduledDate = alertStartTZ.isBefore(now)
          ? tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        reminderHour,
        reminderMinute,
      )
          : alertStartTZ;
    } else {
      // realtime — handled separately in _scheduleImmediate, skip here
      return;
    }

    // Skip if the scheduled time is already past
    if (scheduledDate.isBefore(now)) {
      debugPrint(
        '[Notifications] Skipping "${item.name}" — '
            'scheduled date $scheduledDate is in the past',
      );
      return;
    }

    final notifId = item.id.hashCode.abs();

    debugPrint(
        '[Notifications] "${item.name}" scheduled for: '
            '$scheduledDate | now: $now'
    );

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority:   Priority.high,
          icon: '@drawable/applogo',
          ticker:     item.name,
          // Show big text style for longer messages
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: item.id,
    );

    debugPrint(
      '[Notifications] Scheduled "${item.name}" '
          '(id: $notifId, freq: $frequency) for $scheduledDate',
    );
  }

// ── Real-time: fire shortly for items already in danger zone ─────────────
  static Future<void> _scheduleImmediate(FoodItem item) async {
    final days = item.daysUntilExpiry;

    final String title;
    final String body;

    if (days <= 0) {
      title = '🚨 Expired — ${item.name}';
      body  = '${item.name} has already expired. Time to discard it.';
    } else if (days == 1) {
      title = '⚠️ Last Chance — ${item.name}';
      body  = '${item.name} expires tomorrow. Use it now!';
    } else {
      title = '⏰ Expiring Soon — ${item.name}';
      body  = '${item.name} expires in $days days. Don\'t let it go to waste.';
    }

    final scheduledDate = tz.TZDateTime.now(tz.local)
        .add(const Duration(seconds: 1));

    debugPrint(
      '[Notifications] NOW: ${tz.TZDateTime.now(tz.local)}',
    );

    debugPrint(
      '[Notifications] FIRE AT: $scheduledDate',
    );

    await _plugin.zonedSchedule(
      item.id.hashCode.abs(),
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority:   Priority.max,

          icon: '@drawable/applogo',
          ticker:     item.name,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: item.id,
    );

    debugPrint(
      '[Notifications] Real-time: "${item.name}" fires in 5s '
          '($days days until expiry)',
    );
  }


  static Future<void> scheduleDailyDigest(
      List<FoodItem> items, {
        required int reminderHour,
        required int reminderMinute,
      }) async {
    if (!_initialized) await initialize();

    // ← Don't show anything if inventory is empty
    if (items.isEmpty) {
      debugPrint('[Notifications] Daily digest skipped — no items');
      return;
    }

    final expiringSoon = items.where((i) => i.status == ItemStatus.expiringSoon).length;
    final expired = items.where((i) => i.status == ItemStatus.expired).length;

    String title;
    String body;

    if (expired > 0) {
      title = '🚨 ShelfLife Daily Summary';
      body = '$expired expired item(s), $expiringSoon item(s) expiring soon.';
    } else if (expiringSoon > 0) {
      title = '⚠️ ShelfLife Daily Summary';
      body = '$expiringSoon item(s) are approaching their expiry date.';
    } else {
      title = '✅ ShelfLife Daily Summary';
      body = 'All items are fresh.';
    }

    await _plugin.show(
      777777,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/applogo',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    debugPrint('[Notifications] Daily digest shown');
  }



// ── Schedule for all items ────────────────────────────────────────────────
  static Future<void> scheduleAllFromInventory(
      List<FoodItem> items, {
        int daysBeforeExpiry = 3,
        int reminderHour = 8,
        int reminderMinute = 0,
        String frequency = 'daily',
      }) async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();

    debugPrint('[Notifications] Rescheduling — freq: $frequency, '
        'leadDays: $daysBeforeExpiry, time: $reminderHour:$reminderMinute');

    if (frequency == 'realtime') {
      final danger = items.where(
            (i) => i.status == ItemStatus.expiringSoon || i.status == ItemStatus.expired,
      ).toList();
      for (final item in danger) {
        await showNow(item);
      }
      debugPrint('[Notifications] Real-time: ${danger.length} items notified');
      return;
    }

    // Calculate delay until reminder time today (or tomorrow if passed)
    final now = tz.TZDateTime.now(tz.local);
    var fireAt = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, reminderHour, reminderMinute,
    );
    if (fireAt.isBefore(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    final delay = fireAt.difference(now);

    debugPrint('[Notifications] Will fire in ${delay.inMinutes}m ${delay.inSeconds % 60}s at $fireAt');

    if (frequency == 'daily') {
      // Single digest after delay
      Future.delayed(delay, () async {
        final expiringSoon = items.where((i) => i.status == ItemStatus.expiringSoon).length;
        final expired = items.where((i) => i.status == ItemStatus.expired).length;
        await scheduleDailyDigest(
          items,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
        );
        debugPrint('[Notifications] Daily digest fired');
      });
      return;
    }

    if (frequency == 'once') {
      // Fire each qualifying item after delay
      Future.delayed(delay, () async {
        for (final item in items) {
          if (item.status == ItemStatus.expired) continue;
          if (item.daysUntilExpiry > daysBeforeExpiry) continue;
          await showNow(item);
        }
        debugPrint('[Notifications] Once: fired qualifying items');
      });
      return;
    }
  }


  // ── Cancel one ────────────────────────────────────────────────────────────

  static Future<void> cancelNotification(String itemId) async {
    await _plugin.cancel(itemId.hashCode);
    debugPrint('[Notifications] Cancelled for item $itemId');
  }

  // ── Cancel all ────────────────────────────────────────────────────────────

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[Notifications] All cancelled');
  }


  //persistent notifs



  static Future<void> showPersistentNotification({
    required int totalItems,
    required int expiringSoon,
    required int expired,
  }) async {
    // ← Don't show anything if inventory is empty
    if (totalItems == 0) {
      await cancelPersistentNotification();
      return;
    }
    String title;
    String body;

    if (expired > 0) {
      title = '🚨 ShelfLife Alert';
      body = '$expired expired item(s) need attention';
    }
    else if (expiringSoon > 0) {
      title = '⚠️ ShelfLife Alert';
      body = '$expiringSoon item(s) expiring soon';
    }
    else {
      title = '✅ ShelfLife';
      body = 'All items are fresh';
    }
    await _plugin.show(
      1,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'shelflife_persistent',
          'ShelfLife Monitoring',
          channelDescription: 'Persistent inventory monitoring',
          importance: Importance.low,
          priority: Priority.low,
          autoCancel: true,
          showWhen: false,
          icon: '@drawable/applogo',
        ),
      ),

    );

  }

  static Future<void> cancelPersistentNotification() async {
    await _plugin.cancel(1);
  }
  static Future<void> showNow(FoodItem item) async {
    final days = item.daysUntilExpiry;

    String title;
    String body;

    if (days <= 0) {
      title = '🚨 Expired — ${item.name}';
      body = '${item.name} in your ${item.category.label} has already expired. Consider discarding it.';
    } else if (days == 1) {
      title = '⚠️ Expiring Tomorrow — ${item.name}';
      body = '${item.name} expires tomorrow! Use it today before it goes to waste.';
    } else {
      title = '⏰ Expiring Soon — ${item.name}';
      body = '${item.name} expires in $days days. Check your ${item.category.label} soon.';
    }

    await _plugin.show(
      item.id.hashCode.abs(),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/applogo',
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: item.id,
    );

    debugPrint('[Notifications] Showed "${item.name}" immediately');
  }
  // ── Debug: list pending ───────────────────────────────────────────────────

  static Future<void> debugAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final result = await android?.canScheduleExactNotifications();
    debugPrint('[Notifications] canScheduleExactNotifications: $result');
  }
  static Future<void> debugShowImmediate() async {
    if (!_initialized) await initialize();

    await _plugin.show(
      88888,
      '🔔 Immediate Test',
      'This fires instantly — no scheduling involved',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shelflife_expiry',
          'Expiry Alerts',
          importance: Importance.max,
          priority: Priority.max,

          icon: '@drawable/applogo',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
    debugPrint('[Notifications] Immediate notification sent');
  }
  static Future<void> debugPending() async {
    final pending = await _plugin.pendingNotificationRequests();

    debugPrint(
      '[Notifications] ${pending.length} pending notifications:',
    );

    for (final p in pending) {
      debugPrint(
        'id=${p.id} title=${p.title} body=${p.body}',
      );
    }
  }
}