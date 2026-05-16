// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// 🎨 Smart Campus Identity Hub Theme
/// Unified theme for Student/Lecturer interface
/// Color Scheme: Deep Purple (#512DA8) + Amber (#FFA000)
class AppTheme {
  // ========== COLOR PALETTE ==========

  /// Primary Color - Deep Purple
  static const Color primaryColor = Color(0xFF512DA8); // Deep Purple 700
  static const Color primaryDark = Color(0xFF311B92); // Deep Purple 900
  static const Color primaryLight = Color(0xFF7E57C2); // Deep Purple 400
  static const Color primaryLighter = Color(0xFFD1C4E9); // Deep Purple 100

  /// Accent Color - Amber
  static const Color accentColor = Color(0xFFFFA000); // Amber 700
  static const Color accentDark = Color(0xFFFF8F00); // Amber 800
  static const Color accentLight = Color(0xFFFFB300); // Amber 600

  /// Background Colors (Light)
  static const Color backgroundLight = Color(0xFFF9FAFB); // Light Gray
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure White
  static const Color backgroundCardLight = Color(0xFFFEFEFE); // Card Background

  /// Background Colors (Dark)
  static const Color backgroundDark = Color(0xFF121212); // Dark Gray
  static const Color backgroundSurfaceDark = Color(0xFF1E1E1E); // Surface Dark
  static const Color backgroundCardDark = Color(0xFF2C2C2C); // Card Dark

  /// Text Colors (Light)
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color textSecondary = Color(0xFF757575); // Medium Gray
  static const Color textHint = Color(0xFFBDBDBD); // Light Gray

  /// Text Colors (Dark)
  static const Color textPrimaryDark = Color(0xFFEEEEEE); // Light Gray
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Medium Gray
  static const Color textHintDark = Color(0xFF757575); // Dark Gray

  /// Status Colors
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color infoColor = Color(0xFF2196F3); // Blue

  /// Interaction Type Colors (for timeline)
  static const Color purchaseColor = Color(0xFF7E57C2); // Purple
  static const Color refundColor = Color(0xFF9E9E9E); // Grey
  static const Color borrowColor = Color(0xFF2196F3); // Blue
  static const Color returnColor = Color(0xFF009688); // Teal
  static const Color entryColor = Color(0xFF4CAF50); // Green
  static const Color exitColor = Color(0xFF4CAF50); // Green
  static const Color attendanceColor = Color(0xFFFFA000); // Amber
  static const Color bookingColor = Color(0xFF3F51B5); // Indigo

  /// Achievement Tier Colors
  static const Color bronzeColor = Color(0xFFCD7F32);
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color platinumColor = Color(0xFF512DA8);

  // ========== TYPOGRAPHY ==========

  static const String fontFamily = 'Roboto';

  // Light Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textHint,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Dark Text Styles
  static const TextStyle heading1Dark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryDark,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2Dark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryDark,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3Dark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryDark,
  );

  static const TextStyle bodyLargeDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryDark,
    height: 1.5,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimaryDark,
    height: 1.5,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryDark,
    height: 1.5,
  );

  static const TextStyle captionDark = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textHintDark,
  );

  // ========== SPACING ==========
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // ========== BORDER RADIUS ==========
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // ========== ELEVATION & SHADOWS ==========
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  // ========== ANIMATIONS ==========
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeInOut;

  // ========== HELPER METHODS ==========

  /// Get color for interaction type
  static Color getInteractionColor(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return purchaseColor;
      case 'refund':
        return refundColor;
      case 'borrow':
        return borrowColor;
      case 'return':
        return returnColor;
      case 'entry':
      case 'exit':
        return entryColor;
      case 'attendance':
        return attendanceColor;
      case 'booking':
        return bookingColor;
      default:
        return textSecondary;
    }
  }

  /// Get icon for interaction type
  static IconData getInteractionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return Icons.shopping_cart_outlined;
      case 'refund':
        return Icons.replay;
      case 'borrow':
        return Icons.book_outlined;
      case 'return':
        return Icons.assignment_return_outlined;
      case 'entry':
        return Icons.login;
      case 'exit':
        return Icons.logout;
      case 'attendance':
        return Icons.school_outlined;
      case 'booking':
        return Icons.event_seat_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  /// Get achievement color by tier
  static Color getAchievementColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return bronzeColor;
      case 'silver':
        return silverColor;
      case 'gold':
        return goldColor;
      case 'platinum':
      case 'purple':
        return platinumColor;
      default:
        return textSecondary;
    }
  }

  /// 🌞 Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundLight,
        surface: backgroundWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: fontFamily,
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: button,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: elevationLow,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      // M3 Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundLight,
        indicatorColor: primaryLighter,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryDark);
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return bodySmall.copyWith(
                color: primaryDark, fontWeight: FontWeight.bold);
          }
          return bodySmall.copyWith(color: textSecondary);
        }),
      ),

      // M3 Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: button,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationLow,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLighter,
        labelStyle: bodySmall.copyWith(color: primaryDark),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSM,
          vertical: spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      dividerColor: Colors.grey.shade300,
      // 🐇 Global Bouncy Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: BouncyPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // Keep iOS native feel or use Bouncy
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// 🌙 Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryLight, // Lighter primary for dark mode
        secondary: accentLight, // Lighter accent for dark mode
        background: backgroundDark,
        surface: backgroundSurfaceDark,
        brightness: Brightness.dark,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: fontFamily,
      textTheme: const TextTheme(
        displayLarge: heading1Dark,
        displayMedium: heading2Dark,
        displaySmall: heading3Dark,
        bodyLarge: bodyLargeDark,
        bodyMedium: bodyMediumDark,
        bodySmall: bodySmallDark,
        labelLarge: button,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSurfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: backgroundCardDark,
        elevation: elevationLow,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      
      // M3 Navigation Bar Theme (Dark)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundSurfaceDark,
        indicatorColor: primaryColor, // Using primaryColor (Deep Purple) as indicator in dark mode
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: textSecondaryDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return bodySmallDark.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold);
          }
          return bodySmallDark.copyWith(color: textSecondaryDark);
        }),
      ),

      // M3 Filled Button Theme (Dark)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: button,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: elevationLow,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundSurfaceDark,
        labelStyle: bodySmallDark.copyWith(color: primaryLight),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSM,
          vertical: spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          side: const BorderSide(color: primaryLight),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimaryDark),
      dividerColor: Colors.grey.shade800,
      // 🐇 Global Bouncy Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: BouncyPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 🎈 Custom "Q-Tan" (Bouncy) Page Transition
/// Gives a playful, fluid feel to screen switching
class BouncyPageTransitionsBuilder extends PageTransitionsBuilder {
  const BouncyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 1. Scale Effect (Zoom in with bounce)
    final scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack), // 🐇 The "Bounce"
      ),
    );

    // 2. Slide Effect (Subtle upward drift)
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    // 3. Fade Effect (Smooth entry)
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }
}
