import 'package:flutter/material.dart';

/// Exact Zoho Books Design System
/// Clean, minimal, white backgrounds, sharp corners
class AppTheme {
  // ==================== COLORS ====================

  // Backgrounds
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure white
  static const Color backgroundGray = Color(0xFFF9FAFB); // Very light gray
  static const Color backgroundGrey = Color(
    0xFFF3F4F6,
  ); // Standard gray background

  // Sidebar & TopBar
  static const Color sidebarDark = Color(0xFF283342); // Dark sidebar
  static const Color topbarWhite = Color(0xFFFFFFFF); // WHITE topbar

  // Primary Colors
  static const Color primaryBlue = Color(0xFF2F5BEA);
  static const Color accentOrange = Color(0xFFFF7849);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textMuted = Color(0xFF9CA3AF); // Light gray

  // Borders
  static const Color borderLight = Color(0xFFE5E7EB); // Light gray border
  static const Color borderMedium = Color(0xFFD1D5DB); // Medium gray border

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ==================== TYPOGRAPHY ====================

  // Font Sizes
  static const double fontSizeXSmall = 11.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 13.0;
  static const double fontSizeLarge = 14.0;
  static const double fontSizeXLarge = 16.0;
  static const double fontSizeHeading3 = 16.0;
  static const double fontSizeHeading2 = 18.0;
  static const double fontSizeHeading1 = 20.0;

  // Font Weights
  static const FontWeight fontRegular = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemibold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: fontSizeHeading1,
    fontWeight: fontBold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: fontSizeHeading2,
    fontWeight: fontSemibold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: fontSizeHeading3,
    fontWeight: fontSemibold,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSizeLarge,
    fontWeight: fontRegular,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontRegular,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontRegular,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontSemibold,
    color: Colors.white,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: fontSizeXSmall,
    fontWeight: fontBold,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // ==================== SIZING ====================

  static const double sidebarWidth = 218.0;
  static const double topbarHeight = 56.0;
  static const double inputHeight = 34.0;
  static const double buttonHeight = 34.0;

  // ==================== BORDER RADIUS ====================

  static const double radiusSmall = 3.0;
  static const double radiusMedium = 4.0;
  static const double radiusLarge = 6.0;

  // ==================== SPACING ====================

  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;

  // ADD THESE TWO STYLES TO FIX THE COMPILATION ERRORS
  static TextStyle bodyMediumBold = bodyMedium.copyWith(fontWeight: fontBold);

  static TextStyle bodySmallBold = bodySmall.copyWith(fontWeight: fontBold);
  // ==================== THEME DATA ====================

  // added 28-dec-2025//
  // ADD THESE TO YOUR app_theme.dart FILE
  // Copy and paste inside the AppTheme class
  // Add these text styles:
  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLargeBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  // Add ONLY this color (you already have danger):
  static const Color error = Color(0xFFDC3545);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // DONE! Now the payment widgets will compile without errors.
  //end of this add//

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundWhite,
      fontFamily: 'Inter',

      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        hintStyle: bodyMedium.copyWith(color: textMuted),
        isDense: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(80, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontMedium,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontMedium,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: textSecondary, size: 20),

      tabBarTheme: const TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: textSecondary,
        labelStyle: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontSemibold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontRegular,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: backgroundWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    );
  }
}
