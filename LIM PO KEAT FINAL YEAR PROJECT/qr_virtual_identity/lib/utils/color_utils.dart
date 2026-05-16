// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

/// Utility functions for safe color operations
class ColorUtils {
  /// Safely applies opacity to a color, clamping the opacity value to [0.0, 1.0]
  /// This prevents "opacity >= 0.0 && opacity <= 1.0" assertion errors
  static Color safeOpacity(Color color, double opacity) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    return color.withOpacity(clampedOpacity);
  }

  /// Calculates opacity based on a condition
  /// Returns fullOpacity if condition is true, otherwise returns reducedOpacity
  static double conditionalOpacity({
    required bool condition,
    double fullOpacity = 1.0,
    double reducedOpacity = 0.3,
  }) {
    return (condition ? fullOpacity : reducedOpacity).clamp(0.0, 1.0);
  }

  /// Applies opacity to a color based on a boolean condition
  static Color withConditionalOpacity(
    Color color, {
    required bool condition,
    double fullOpacity = 1.0,
    double reducedOpacity = 0.3,
  }) {
    final opacity = conditionalOpacity(
      condition: condition,
      fullOpacity: fullOpacity,
      reducedOpacity: reducedOpacity,
    );
    return color.withOpacity(opacity);
  }
}
