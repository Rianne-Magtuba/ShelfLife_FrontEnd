import 'package:flutter/material.dart';
import 'models/models.dart';

/// Static mock data — replace with real API/local DB calls later.
class MockData {
  static final DateTime _now = DateTime.now();

  // ─── Food Items ────────────────────────────────────────────────────────────

  static List<FoodItem> get items => [
        FoodItem(
          id: '1',
          name: 'Chicken Breast',
          category: ItemCategory.freezer,
          quantity: 2,
          weight: '500',
          weightUnit: 'g',
          expiryDate: _now.add(const Duration(days: 1)),
          dateAdded: _now.subtract(const Duration(days: 3)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 185.00,
          purchaseDate: _now.subtract(const Duration(days: 3)),
        ),
        FoodItem(
          id: '2',
          name: 'Milk',
          category: ItemCategory.fridge,
          quantity: 1,
          weight: '1',
          weightUnit: 'L',
          expiryDate: _now.add(const Duration(days: 2)),
          dateAdded: _now.subtract(const Duration(days: 5)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 78.00,
          purchaseDate: _now.subtract(const Duration(days: 5)),
          consumeWithinDays: 3,
        ),
        FoodItem(
          id: '3',
          name: 'Greek Yogurt',
          category: ItemCategory.fridge,
          quantity: 3,
          weight: '150',
          weightUnit: 'g',
          expiryDate: _now.add(const Duration(days: 7)),
          dateAdded: _now.subtract(const Duration(days: 2)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 65.00,
          purchaseDate: _now.subtract(const Duration(days: 2)),
        ),
        FoodItem(
          id: '4',
          name: 'White Rice',
          category: ItemCategory.pantry,
          quantity: 1,
          weight: '5',
          weightUnit: 'kg',
          expiryDate: _now.add(const Duration(days: 180)),
          dateAdded: _now.subtract(const Duration(days: 10)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 250.00,
          purchaseDate: _now.subtract(const Duration(days: 10)),
        ),
        FoodItem(
          id: '5',
          name: 'Spinach',
          category: ItemCategory.fridge,
          quantity: 1,
          weight: '200',
          weightUnit: 'g',
          expiryDate: _now.add(const Duration(days: 3)),
          dateAdded: _now.subtract(const Duration(days: 1)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 45.00,
        ),
        FoodItem(
          id: '6',
          name: 'Lettuce',
          category: ItemCategory.fridge,
          quantity: 1,
          weight: '1',
          weightUnit: 'g',
          expiryDate: _now.subtract(const Duration(days: 3)),
          dateAdded: _now.subtract(const Duration(days: 10)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 35.00,
        ),
        FoodItem(
          id: '7',
          name: 'Strawberries',
          category: ItemCategory.fridge,
          quantity: 1,
          weight: '250',
          weightUnit: 'g',
          expiryDate: _now.subtract(const Duration(days: 2)),
          dateAdded: _now.subtract(const Duration(days: 8)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 95.00,
        ),
        FoodItem(
          id: '8',
          name: 'Ham',
          category: ItemCategory.fridge,
          quantity: 1,
          weight: '300',
          weightUnit: 'g',
          expiryDate: _now.subtract(const Duration(days: 1)),
          dateAdded: _now.subtract(const Duration(days: 12)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 120.00,
        ),
        FoodItem(
          id: '9',
          name: 'Frozen Peas',
          category: ItemCategory.freezer,
          quantity: 2,
          weight: '400',
          weightUnit: 'g',
          expiryDate: _now.add(const Duration(days: 90)),
          dateAdded: _now.subtract(const Duration(days: 7)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 55.00,
        ),
        FoodItem(
          id: '10',
          name: 'Soy Sauce',
          category: ItemCategory.pantry,
          quantity: 1,
          weight: '500',
          weightUnit: 'ml',
          expiryDate: _now.add(const Duration(days: 365)),
          dateAdded: _now.subtract(const Duration(days: 20)),
          imagePath: 'assets/images/placeholder.png',
          purchasePrice: 38.00,
        ),
      ];

  // ─── Notifications ─────────────────────────────────────────────────────────

  static List<AppNotification> get notifications => [
        AppNotification(
          id: 'n1',
          itemId: '1',
          itemName: 'Chicken Breast',
          message: 'Chicken Breast has expired',
          subtitle:
              'Expired on ${_formatDate(_now.subtract(const Duration(days: 1)))}',
          timestamp: _now.subtract(const Duration(hours: 2)),
          isRead: false,
          type: NotificationType.expired,
          daysLeft: 0,
        ),
        AppNotification(
          id: 'n2',
          itemId: '2',
          itemName: 'Milk',
          message: 'Milk expiring soon',
          subtitle:
              'Will expire on ${_formatDate(_now.add(const Duration(days: 2)))}',
          timestamp: _now.subtract(const Duration(hours: 5)),
          isRead: false,
          type: NotificationType.expiringSoon,
          daysLeft: 2,
        ),
        AppNotification(
          id: 'n3',
          itemId: '3',
          itemName: 'Greek Yogurt',
          message: 'Greek Yogurt consumed on time!',
          subtitle: 'Great job preventing food waste',
          timestamp: _now.subtract(const Duration(hours: 3)),
          isRead: true,
          type: NotificationType.consumed,
        ),
        AppNotification(
          id: 'n4',
          itemId: '7',
          itemName: 'Strawberries',
          message: 'New item added',
          subtitle: 'Strawberries added to Fridge',
          timestamp: _now.subtract(const Duration(hours: 6)),
          isRead: true,
          type: NotificationType.added,
        ),
        AppNotification(
          id: 'n5',
          itemId: '5',
          itemName: 'Spinach',
          message: 'Spinach expiring soon',
          subtitle:
              'Will expire on ${_formatDate(_now.add(const Duration(days: 3)))}',
          timestamp: _now.subtract(const Duration(hours: 8)),
          isRead: false,
          type: NotificationType.expiringSoon,
          daysLeft: 3,
        ),
      ];

  // ─── User ──────────────────────────────────────────────────────────────────

  static UserProfile get user => UserProfile(
        id: 'u1',
        username: 'arrr',
        email: 'p.rat@email.com',
        displayName: 'Pie Ratatouille',
      );

  static NotificationSettings get notifSettings => NotificationSettings(
        enabled: true,
        alertLeadDays: 3,
        dailyReminderTime: const TimeOfDay(hour: 8, minute: 0),
        frequency: 'daily',
      );

  // ─── Statistics ────────────────────────────────────────────────────────────

  static Map<String, dynamic> get statistics => {
        'totalAdded': 24,
        'totalExpired': 6,
        'totalConsumed': 18,
        'estimatedWasteCost': 413.00,
        'categoryBreakdown': {
          'Fridge': 5,
          'Pantry': 2,
          'Freezer': 2,
          'Others': 1,
        },
        'expiryTimeline': {
          'Mon': 1,
          'Tue': 2,
          'Wed': 0,
          'Thu': 1,
          'Fri': 3,
          'Sat': 1,
          'Sun': 0,
        },
        'wastedByCategory': {
          'Fridge': 8,
          'Pantry': 3,
          'Freezer': 2,
          'Others': 1,
        },
      };

  // ─── FAQ ──────────────────────────────────────────────────────────────────

  static List<Map<String, String>> get faqs => [
        {
          'q': 'How do I scan an expiry date?',
          'a':
              'Tap the Scan button in Add Item. Point your camera at the expiry date printed on the package. The app will automatically detect and parse the date.',
        },
        {
          'q': 'How does the expiry alert work?',
          'a':
              'You can set how many days before expiry you want to be notified (1, 3, 5, or 7 days) in Notification Settings. The app sends a push notification at your chosen daily reminder time.',
        },
        {
          'q': 'Can I track multiple quantities of the same item?',
          'a':
              'Yes! Use the quantity stepper in the Add Item screen to set how many units you have. Each item card shows the quantity in the inventory list.',
        },
        {
          'q': 'What does "After Opening" mean?',
          'a':
              '"Consume Within (Days)" tracks how many days an item is safe to use after being opened, separate from the printed expiry date.',
        },
        {
          'q': 'How is estimated waste cost calculated?',
          'a':
              'When you add an item, you can enter its purchase price. If the item expires without being consumed, its price is added to your estimated waste cost shown in Statistics.',
        },
        {
          'q': 'Is my data stored online?',
          'a':
              'Currently all data is stored locally on your device. Cloud sync is coming in a future update.',
        },
      ];

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
