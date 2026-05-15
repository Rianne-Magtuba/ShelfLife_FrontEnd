import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/models.dart';

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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notifications] Tapped: ${details.payload}');
        // TODO: navigate to item detail using details.payload as itemId
      },
    );

    _initialized = true;
    debugPrint('[Notifications] Initialized');
  }

  // ── Request permission ────────────────────────────────────────────────────
  // THIS was the broken part — generics must be inline, not on a new line

  static Future<bool> requestPermission() async {
    bool granted = false;

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final result = await android.requestNotificationsPermission();
      granted = result ?? false;
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
    return granted;
  }

  // ── Schedule for one item ─────────────────────────────────────────────────

  static Future<void> scheduleExpiryNotification(
      FoodItem item, {
        int daysBeforeExpiry = 3,
      }) async {
    final notifyDateTime = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day - daysBeforeExpiry,
      8, // 8:00 AM
      0,
    );

    if (notifyDateTime.isBefore(DateTime.now())) {
      debugPrint(
        '[Notifications] Skipping "${item.name}" — '
            'notify date is already past',
      );
      return;
    }

    final scheduledDate = tz.TZDateTime.from(notifyDateTime, tz.local);
    final notifId = item.id.hashCode;

    await _plugin.zonedSchedule(
      notifId,
      'ShelfLife — Expiring Soon',
      '${item.name} expires in $daysBeforeExpiry days! '
          'Check your ${item.category.label}.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority:   Priority.high,
          ticker:     item.id,
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
          '(notifId: $notifId) for ${scheduledDate.toLocal()}',
    );
  }

  // ── Schedule for all items ────────────────────────────────────────────────

  static Future<void> scheduleAllFromInventory(
      List<FoodItem> items, {
        int daysBeforeExpiry = 3,
      }) async {
    await _plugin.cancelAll();

    int scheduled = 0;
    for (final item in items) {
      if (item.status != ItemStatus.expired) {
        await scheduleExpiryNotification(
          item,
          daysBeforeExpiry: daysBeforeExpiry,
        );
        scheduled++;
      }
    }

    debugPrint(
      '[Notifications] Scheduled $scheduled of ${items.length} items',
    );
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

  // ── Debug: list pending ───────────────────────────────────────────────────

  static Future<void> debugListPending() async {
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('[Notifications] ${pending.length} pending:');
    for (final n in pending) {
      debugPrint('  id=${n.id}  title=${n.title}');
    }
  }

  // ── Debug: fire in N seconds ──────────────────────────────────────────────
  // Use this to test notifications without waiting days

  static Future<void> debugScheduleInSeconds(
      FoodItem item, {
        int seconds = 5,
      }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local)
        .add(Duration(seconds: seconds));

    await _plugin.zonedSchedule(
      item.id.hashCode,
      'ShelfLife — Test Notification',
      '${item.name} — notification is working!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority:   Priority.max,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: item.id,
    );

    debugPrint(
      '[Notifications] Debug: "${item.name}" fires in ${seconds}s',
    );
  }
}