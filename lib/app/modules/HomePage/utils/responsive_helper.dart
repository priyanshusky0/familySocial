import 'package:flutter/material.dart';

/// Responsive Helper Class
/// Provides responsive utilities for scaling UI elements
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  // Screen dimensions
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  double get screenPadding => MediaQuery.of(context).padding.top;

  // Device type checks
  bool get isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;
  bool get isTablet => screenWidth > 600;
  bool get isPhone => screenWidth < 600;

  // Base width for scaling (iPhone 11 Pro width)
  static const double _baseWidth = 375.0;

  /// Scale font size based on screen width
  double fontSize(double baseSize) {
    return baseSize * (screenWidth / _baseWidth);
  }

  /// Scale spacing based on screen width
  double spacing(double baseSpacing) {
    return baseSpacing * (screenWidth / _baseWidth);
  }

  /// Get responsive padding (symmetric)
  EdgeInsets paddingSymmetric({
    required double horizontal,
    required double vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: spacing(horizontal),
      vertical: spacing(vertical),
    );
  }

  /// Get responsive padding (all sides)
  EdgeInsets paddingAll(double value) {
    return EdgeInsets.all(spacing(value));
  }

  /// Get responsive padding (custom sides)
  EdgeInsets paddingFromLTRB(double l, double t, double r, double b) {
    return EdgeInsets.fromLTRB(
      spacing(l),
      spacing(t),
      spacing(r),
      spacing(b),
    );
  }

  /// Get responsive padding (only specific sides)
  EdgeInsets paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: spacing(left),
      top: spacing(top),
      right: spacing(right),
      bottom: spacing(bottom),
    );
  }

  /// Get width as percentage of screen width
  double width(double percentage) {
    return screenWidth * (percentage / 100);
  }

  /// Get height as percentage of screen height
  double height(double percentage) {
    return screenHeight * (percentage / 100);
  }

  /// Get responsive border radius
  BorderRadius borderRadius(double radius) {
    return BorderRadius.circular(spacing(radius));
  }

  /// Get responsive circular border radius (all corners)
  BorderRadius borderRadiusAll(double radius) {
    return BorderRadius.all(Radius.circular(spacing(radius)));
  }

  /// Get responsive box constraints
  BoxConstraints constraints({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return BoxConstraints(
      minWidth: minWidth != null ? spacing(minWidth) : 0,
      maxWidth: maxWidth != null ? spacing(maxWidth) : double.infinity,
      minHeight: minHeight != null ? spacing(minHeight) : 0,
      maxHeight: maxHeight != null ? spacing(maxHeight) : double.infinity,
    );
  }

  /// Get responsive icon size
  double iconSize(double baseSize) {
    return fontSize(baseSize);
  }

  /// Get responsive image size
  Size imageSize(double width, double height) {
    return Size(spacing(width), spacing(height));
  }
}