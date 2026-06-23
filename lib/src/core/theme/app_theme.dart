import 'package:flutter/material.dart';
import 'package:habitu_ui/habitu_ui.dart';

class AppTheme {
  AppTheme._();

  // ==================== COLORES PRINCIPALES DELEGADOS A habitu_ui ====================
  static const Color surfaceColor = HabituColors.surface;
  static const Color surfaceDim = HabituColors.surfaceDim;
  static const Color surfaceBright = HabituColors.surfaceBright;
  static const Color surfaceContainerLowest = HabituColors.surfaceContainerLowest;
  static const Color surfaceContainerLow = HabituColors.surfaceContainerLow;
  static const Color surfaceContainer = HabituColors.surfaceContainer;
  static const Color surfaceContainerHigh = HabituColors.surfaceContainerHigh;
  static const Color surfaceContainerHighest = HabituColors.surfaceContainerHighest;

  static const Color onSurface = HabituColors.onSurface;
  static const Color onSurfaceVariant = HabituColors.onSurfaceVariant;
  static const Color inverseSurface = HabituColors.inverseSurface;
  static const Color inverseOnSurface = HabituColors.inverseOnSurface;

  static const Color outline = HabituColors.outline;
  static const Color outlineVariant = HabituColors.outlineVariant;

  static const Color primaryColor = HabituColors.primary;
  static const Color onPrimary = HabituColors.onPrimary;
  static const Color primaryContainer = HabituColors.primaryContainer;
  static const Color onPrimaryContainer = HabituColors.onPrimaryContainer;
  static const Color inversePrimary = HabituColors.inversePrimary;

  static const Color secondaryColor = HabituColors.secondary;
  static const Color onSecondary = HabituColors.onSecondary;
  static const Color secondaryContainer = HabituColors.secondaryContainer;
  static const Color onSecondaryContainer = HabituColors.onSecondaryContainer;

  static const Color tertiaryColor = HabituColors.tertiary;
  static const Color onTertiary = HabituColors.onTertiary;
  static const Color tertiaryContainer = HabituColors.tertiaryContainer;
  static const Color onTertiaryContainer = HabituColors.onTertiaryContainer;

  static const Color errorColor = HabituColors.error;
  static const Color onError = HabituColors.onError;
  static const Color errorContainer = HabituColors.errorContainer;
  static const Color onErrorContainer = HabituColors.onErrorContainer;

  static const Color accentColor = HabituColors.accent;

  static const Color primaryFixed = HabituColors.primaryFixed;
  static const Color primaryFixedDim = HabituColors.primaryFixedDim;
  static const Color onPrimaryFixed = HabituColors.onPrimaryFixed;
  static const Color onPrimaryFixedVariant = HabituColors.onPrimaryFixedVariant;

  static const Color secondaryFixed = HabituColors.secondaryFixed;
  static const Color secondaryFixedDim = HabituColors.secondaryFixedDim;
  static const Color onSecondaryFixed = HabituColors.onSecondaryFixed;
  static const Color onSecondaryFixedVariant = HabituColors.onSecondaryFixedVariant;

  static const Color tertiaryFixed = HabituColors.tertiaryFixed;
  static const Color tertiaryFixedDim = HabituColors.tertiaryFixedDim;
  static const Color onTertiaryFixed = HabituColors.onTertiaryFixed;
  static const Color onTertiaryFixedVariant = HabituColors.onTertiaryFixedVariant;

  // Paleta de colores para hábitos
  static const List<Color> habitColors = HabituColors.habitColors;
  static const List<String> habitColorHexes = HabituColors.habitColorHexes;

  static ThemeData getLightTheme() => HabituTheme.lightTheme;
  static ThemeData getDarkTheme() => HabituTheme.darkTheme;
}
