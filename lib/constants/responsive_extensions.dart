import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  double w(double percentage) => screenWidth * percentage;
  double h(double percentage) => screenHeight * percentage;

  double get scale {
    const baseWidth = 375.0;
    return screenWidth / baseWidth;
  }

  double sp(double size) => size * scale;
}