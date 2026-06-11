import 'package:flutter/material.dart';

class AppTheme {
  // ==================== COLORES PRINCIPALES (Academic Ethereal) ====================
  static const Color surfaceColor = Color(0xFF121413);
  static const Color surfaceDim = Color(0xFF121413);
  static const Color surfaceBright = Color(0xFF383938);
  static const Color surfaceContainerLowest = Color(0xFF0D0E0E);
  static const Color surfaceContainerLow = Color(0xFF1A1C1B);
  static const Color surfaceContainer = Color(0xFF1E201F);
  static const Color surfaceContainerHigh = Color(0xFF292A29);
  static const Color surfaceContainerHighest = Color(0xFF343534);

  static const Color onSurface = Color(0xFFE3E2E0);
  static const Color onSurfaceVariant = Color(0xFFC3C6D1);
  static const Color inverseSurface = Color(0xFFE3E2E0);
  static const Color inverseOnSurface = Color(0xFF2F3130);

  static const Color outline = Color(0xFF8D919A);
  static const Color outlineVariant = Color(0xFF43474F);

  static const Color primaryColor = Color(0xFFA7C8FF); // Pastel Blue
  static const Color onPrimary = Color(0xFF003061);
  static const Color primaryContainer = Color(0xFF003366);
  static const Color onPrimaryContainer = Color(0xFF799DD6);
  static const Color inversePrimary = Color(0xFF3A5F94);

  static const Color secondaryColor = Color(0xFFC6C6CA); // Desaturated secondary
  static const Color onSecondary = Color(0xFF2F3034);
  static const Color secondaryContainer = Color(0xFF4A4B4F);
  static const Color onSecondaryContainer = Color(0xFFBBBBBF);

  static const Color tertiaryColor = Color(0xFF96D3BD); // Desaturated Mint
  static const Color onTertiary = Color(0xFF00382B);
  static const Color tertiaryContainer = Color(0xFF003B2D);
  static const Color onTertiaryContainer = Color(0xFF6BA792);

  static const Color errorColor = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color accentColor = Color(0xFFF59E0B); // Amber 500

  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color primaryFixedDim = Color(0xFFA7C8FF);
  static const Color onPrimaryFixed = Color(0xFF001B3C);
  static const Color onPrimaryFixedVariant = Color(0xFF1F477B);

  static const Color secondaryFixed = Color(0xFFE2E2E6);
  static const Color secondaryFixedDim = Color(0xFFC6C6CA);
  static const Color onSecondaryFixed = Color(0xFF1A1C1F);
  static const Color onSecondaryFixedVariant = Color(0xFF45474A);

  static const Color tertiaryFixed = Color(0xFFB1EFD8);
  static const Color tertiaryFixedDim = Color(0xFF96D3BD);
  static const Color onTertiaryFixed = Color(0xFF002118);
  static const Color onTertiaryFixedVariant = Color(0xFF0D503F);

  // Paleta de colores para hábitos
  static const List<Color> habitColors = [
    Color(0xFFA7C8FF), // Pastel Blue (Estudio)
    Color(0xFF96D3BD), // Mint (Salud / Bienestar)
    Color(0xFFE2B2B2), // Pastel Red/Rose (Deporte)
    Color(0xFFE2D6B2), // Pastel Yellow/Sand (Sueño)
    Color(0xFFC6C6CA), // Slate (Rutina)
    Color(0xFFD0B2E2), // Lavender (Social)
  ];

  static const List<String> habitColorHexes = [
    '#A7C8FF',
    '#96D3BD',
    '#E2B2B2',
    '#E2D6B2',
    '#C6C6CA',
    '#D0B2E2',
  ];

  static ThemeData getLightTheme() => _buildTheme(Brightness.light);
  static ThemeData getDarkTheme() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color background = isDark ? surfaceColor : const Color(0xFFF9F9F8); // Bone/Warm white
    final Color cardBg = isDark ? surfaceContainer : Colors.white;
    final Color textPrimary = isDark ? onSurface : const Color(0xFF1C1B1B);
    final Color textSecondary = isDark ? onSurfaceVariant : const Color(0xFF606164);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondaryColor,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiaryColor,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: errorColor,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: isDark ? surfaceColor : const Color(0xFFF9F9F8),
        onSurface: textPrimary,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? outlineVariant.withOpacity(0.3) : const Color(0xFFE5E5E3),
            width: 1.0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: isDark ? outlineVariant : const Color(0xFFC6C6CA), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceContainerLow : const Color(0xFFF0F0EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontFamily: 'Inter'),
        labelStyle: TextStyle(color: textSecondary, fontFamily: 'Inter'),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? surfaceContainerLowest : Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Inter'),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 48, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.02),
        headlineLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.01),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.normal, color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
        labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, letterSpacing: 0.01),
        labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.05),
      ),
    );
  }
}
