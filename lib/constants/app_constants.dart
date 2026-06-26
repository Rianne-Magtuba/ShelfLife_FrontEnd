import 'package:flutter/material.dart';
import '../core/common/utils/weight_converter.dart';


class AppColors {
  // Primary palette
  static const Color darkBlue = Color(0xFF223A5E);
  static const Color mediumBlue = Color(0xFF4E7BB5);
  static const Color lightBlue = Color(0xFFC9DBF1);
  static const Color brown = Color(0xFF6B4A2B);
  static const Color cream = Color(0xFFF2EADF);

  // Buttons
  static const Color buttonBlue = Color(0xFF4E7BB6);
  static const Color buttonText = Colors.white;

  // Background gradient
  static const Color gradientStart = Colors.white;
  static const Color gradientEnd = Color(0xFFD4E4FF);

  // Status colors
  static const Color fresh = Color(0xFF2E7D32);
  static const Color freshBg = Color(0xFFE8F5E9);
  static const Color expiring = Color(0xFFF57F17);
  static const Color expiringBg = Color(0xFFFFF8E1);
  static const Color expired = Color(0xFFC62828);
  static const Color expiredBg = Color(0xFFFFEBEE);

  // Neutral
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4F59);
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);
  static const Color inputBg = Color(0xFFF9FAFB);


}

class AppStrings {
  static const String appName = '';
  static const String tagline = 'Smart food inventory management app';

  // Splash
  static const List<Map<String, String>> splashSlides = [
    {
      'title': 'Scan Expiration Dates',
      'subtitle':
          'Quickly add items by scanning product labels with your camera',
      'vector': 'assets/svg/splashvector1.svg',
    },
    {
      'title': 'Track your Inventory',
      'subtitle': 'Keep all your food items organized in one convenient place',
      'vector': 'assets/svg/splashvector2.svg',
    },
    {
      'title': 'Get Timely Alerts',
      'subtitle': 'Never waste food again with smart expiration notifications',
      'vector': 'assets/images/replacement3.png',
    },
  ];

  // Categories
  static const List<String> categories = [
    'All',
    'Fridge',
    'Pantry',
    'Freezer',
    'Others'
  ];
  static const List<String> categoriesNoAll = [
    'Fridge',
    'Pantry',
    'Freezer',
    'Others'
  ];

  // Sort options
  static const List<String> sortOptions = [
    'Expiry (Soonest)',
    'Expiry (Latest)',
    'Name A–Z',
    'Name Z–A',
    'Date Added',
  ];

  // Weight units
  //static const List<String> weightUnits = ['g', 'kg', 'ml', 'L'];
  static const List<String> weightUnits = WeightConverter.supportedUnits;

  // Alert lead times
  static const List<int> alertLeadTimes = [1, 3, 5, 7];
}

class AppSizes {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static const double navBarHeight = 72.0;
  static const double fabSize = 56.0;
}
