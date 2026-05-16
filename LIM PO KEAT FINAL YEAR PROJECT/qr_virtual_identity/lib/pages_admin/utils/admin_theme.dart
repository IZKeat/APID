// lib/pages_admin/utils/admin_theme.dart
import 'package:flutter/material.dart';

/// 🎨 Admin Dashboard Theme (Material 3 + Jelly Design)
/// 
/// Implements a vibrant, youthful design language using Material 3.
/// Includes custom extensions for "Jelly" physics and animations.
class AdminTheme {
  // ========== SEED COLORS (M3) ==========
  // We use a seed color to generate a harmonious tonal palette.
  static const Color _seedColor = Color(0xFF673AB7); // Deep Purple
  static const Color _secondarySeed = Color(0xFFFFC107); // Amber

  // ========== CUSTOM COLORS (Vibrant) ==========
  // High saturation colors for that "Pop" effect
  static const Color jellyPurple = Color(0xFF8B5CF6);
  static const Color jellyPink = Color(0xFFEC4899);
  static const Color jellyBlue = Color(0xFF3B82F6);
  static const Color jellyGreen = Color(0xFF10B981);
  static const Color jellyOrange = Color(0xFFF59E0B);
  static const Color jellyRed = Color(0xFFEF4444);

  // ========== THEME DATA ==========
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        secondary: _secondarySeed,
        surface: const Color(0xFFF8FAFC), // Slate 50 (Crisp White-ish)
      ),
      
      // 🖋️ Typography (Modern & Clean)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1.0),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),

      // 🃏 Card Theme (Jelly Base)
      cardTheme: CardThemeData(
        elevation: 0, // We use custom shadows
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent, // Remove M3 tint for cleaner look
      ),

      // 🔘 Button Theme (Bouncy)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // 🧩 Extensions
      extensions: <ThemeExtension<dynamic>>[
        const JellyThemeExtension(
          curve: Curves.elasticOut,
          duration: Duration(milliseconds: 800),
          cardScale: 1.02,
        ),
      ],
    );
  }

  // ========== HELPER METHODS (Legacy Support) ==========
  // Keeping these for backward compatibility during refactor, 
  // but mapped to new M3 colors where possible.

  static Color getScanPointTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'commerce': return jellyGreen;
      case 'library': return jellyBlue;
      case 'access': return jellyOrange;
      case 'booking': return jellyPurple;
      default: return Colors.grey;
    }
  }

  static IconData getScanPointTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'commerce': return Icons.store_rounded;
      case 'library': return Icons.local_library_rounded;
      case 'access': return Icons.meeting_room_rounded;
      case 'booking': return Icons.event_seat_rounded;
      default: return Icons.qr_code_rounded;
    }
  }

  // ========== TYPOGRAPHY SHORTHANDS ==========
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // ========== BADGE BUILDERS ==========
  static Widget typeBadge(String text, Color color, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static Widget statusBadge(String status, {double fontSize = 12}) {
    final statusLower = status.toLowerCase();
    final color = _statusColor(statusLower);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Color _statusColor(String statusLower) {
    switch (statusLower) {
      case 'success':
      case 'active':
      case 'online':
        return successColor;
      case 'pending':
      case 'in_review':
        return infoColor;
      case 'error':
      case 'failed':
      case 'banned':
        return jellyRed;
      default:
        return Colors.grey;
    }
  }

  static Color getRoleColor(dynamic role) {
    switch (role?.toString().toLowerCase()) {
      case 'admin':
        return jellyPurple;
      case 'merchant':
        return jellyOrange;
      case 'student':
        return jellyBlue;
      case 'guest':
        return Colors.grey;
      default:
        return jellyGreen;
    }
  }

  // ========== INTERACTION HELPERS ==========
  static Color getInteractionTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'purchase':
        return jellyGreen;
      case 'refund':
        return jellyRed;
      case 'borrow':
        return jellyBlue;
      case 'return':
        return jellyOrange;
      case 'entry':
      case 'exit':
        return jellyPurple;
      case 'attendance':
        return jellyPink;
      case 'booking':
        return jellyBlue;
      default:
        return Colors.grey;
    }
  }

  static IconData getInteractionTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'purchase':
        return Icons.shopping_cart_checkout_rounded;
      case 'refund':
        return Icons.reply_rounded;
      case 'borrow':
        return Icons.menu_book_rounded;
      case 'return':
        return Icons.keyboard_return_rounded;
      case 'entry':
        return Icons.login_rounded;
      case 'exit':
        return Icons.logout_rounded;
      case 'attendance':
        return Icons.event_available_rounded;
      case 'booking':
        return Icons.event_seat_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ========== DEPRECATED CONSTANTS (Mapped for safety) ==========
  static const Color primaryColor = _seedColor;
  static const Color accentColor = jellyPurple;
  static const Color successColor = Color(0xFF22C55E);
  static const Color infoColor = Color(0xFF0EA5E9);
  static const Color commerceColor = jellyGreen;
  static const Color libraryColor = jellyBlue;
  static const Color accessColor = jellyOrange;
  static const Color bookingTypeColor = jellyPurple;
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundWhite = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
}

/// 🍮 Jelly Theme Extension
/// Defines the physics and constants for the "Jelly" feel.
@immutable
class JellyThemeExtension extends ThemeExtension<JellyThemeExtension> {
  final Curve curve;
  final Duration duration;
  final double cardScale;

  const JellyThemeExtension({
    required this.curve,
    required this.duration,
    required this.cardScale,
  });

  @override
  JellyThemeExtension copyWith({Curve? curve, Duration? duration, double? cardScale}) {
    return JellyThemeExtension(
      curve: curve ?? this.curve,
      duration: duration ?? this.duration,
      cardScale: cardScale ?? this.cardScale,
    );
  }

  @override
  JellyThemeExtension lerp(ThemeExtension<JellyThemeExtension>? other, double t) {
    if (other is! JellyThemeExtension) return this;
    return JellyThemeExtension(
      curve: other.curve, // Curves don't lerp well, stick to target
      duration: other.duration,
      cardScale: other.cardScale, // Could lerp, but constant is fine
    );
  }
}
