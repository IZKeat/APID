import 'package:flutter/material.dart';

/// 🎨 Jelly Theme
/// Defines the vibrant, youthful color palette and styles for the Admin Dashboard.
class JellyTheme {
  // ---------------------------------------------------------------------------
  // 🎨 Color Palette (High Saturation / Candy Colors)
  // ---------------------------------------------------------------------------
  
  /// Primary Brand Color: Electric Violet
  /// Used for main actions, active states, and headers.
  static const Color primary = Color(0xFF6200EA); 

  /// Secondary Accent: Lime Green
  /// Used for success states, active indicators, and high-priority highlights.
  static const Color secondary = Color(0xFFAEEA00);

  /// Background: Very Light Lavender
  /// A soft, tinted background to reduce eye strain but keep it lively.
  static const Color background = Color(0xFFF3E5F5);

  /// Surface: Glassmorphism White
  /// Used for cards and containers.
  static const Color surface = Colors.white;

  /// Error: Vibrant Red
  static const Color error = Color(0xFFFF1744);

  /// Warning: Amber
  static const Color warning = Color(0xFFFFC400);

  /// Text Colors
  static const Color textPrimary = Color(0xFF2D0C57); // Deep Purple for readability
  static const Color textSecondary = Color(0xFF9586A8); // Muted Purple

  // ---------------------------------------------------------------------------
  // 📐 Shapes & Radii
  // ---------------------------------------------------------------------------

  /// Standard border radius for "Jelly" cards (24dp)
  static final BorderRadius cardRadius = BorderRadius.circular(24);

  /// Stadium border radius for buttons
  static final BorderRadius buttonRadius = BorderRadius.circular(50);

  // ---------------------------------------------------------------------------
  // 🌘 Shadows (Soft & Colorful)
  // ---------------------------------------------------------------------------

  static List<BoxShadow> get jellyShadow => [
    BoxShadow(
      color: primary.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get hoverShadow => [
    BoxShadow(
      color: primary.withOpacity(0.15),
      blurRadius: 25,
      offset: const Offset(0, 12),
      spreadRadius: 2,
    ),
  ];

  // ---------------------------------------------------------------------------
  // 📝 Text Styles
  // ---------------------------------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  // ---------------------------------------------------------------------------
  // 🧩 Missing Members (Added for compatibility)
  // ---------------------------------------------------------------------------

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const Color success = Color(0xFF00C853); // Vibrant Green
  static const Color info = Color(0xFF2962FF); // Vibrant Blue
  static const Color jellyOrange = Color(0xFFFF6D00); // Vibrant Orange
}
