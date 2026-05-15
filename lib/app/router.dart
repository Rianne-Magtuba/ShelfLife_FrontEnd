import 'package:go_router/go_router.dart';
import '../pages/splash_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/home_page.dart';
import '../pages/inventory_page.dart';
import '../pages/add_item_page.dart';
import '../pages/item_detail_page.dart';
import '../pages/notifications_page.dart';
import '../pages/notification_settings_page.dart';
import '../pages/profile_page.dart';
import '../pages/statistics_page.dart';
import '../pages/help_page.dart';
import '../widgets/main_scaffold.dart'; // ← import scaffold, NOT main.dart
import '../pages/edit_item_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const inventory = '/inventory';
  static const addItem = '/add-item';
  static const itemDetail = '/item-detail';
  static const notifications = '/notifications';
  static const notificationSettings = '/notification-settings';
  static const profile = '/profile';
  static const statistics = '/statistics';
  static const help = '/help';
  static const editItem = '/edit-item';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const RegisterPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.inventory,
          builder: (_, __) => const InventoryPage(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, __) => const ProfilePage(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addItem,
      builder: (_, __) => const AddItemPage(),
    ),
    GoRoute(
      path: AppRoutes.itemDetail,
      builder: (context, state) {
        final itemId = state.extra as String? ?? '';
        return ItemDetailPage(itemId: itemId);
      },
    ),
    GoRoute(
      path: AppRoutes.editItem,
      builder: (context, state) {
        final itemId = state.extra as String? ?? '';
        return EditItemPage(itemId: itemId);
      },
    ),
    GoRoute(
      path: AppRoutes.notificationSettings,
      builder: (_, __) => const NotificationSettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.statistics,
      builder: (_, __) => const StatisticsPage(),
    ),
    GoRoute(
      path: AppRoutes.help,
      builder: (_, __) => const HelpPage(),
    ),

  ],
);
