// lib/ui/theme.dart
import 'package:flutter/material.dart';

/// Espresso-inspired dark theme: near-black background with a warm
/// copper/crema accent.
const Color kAccentColor = Color(0xFFD9974B);
const Color kBackgroundColor = Colors.black;
const Color kSurfaceColor = Color(0xFF1A1712);

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kAccentColor,
    brightness: Brightness.dark,
  ).copyWith(surface: kSurfaceColor);

  return ThemeData.from(
    colorScheme: colorScheme,
    useMaterial3: true,
  ).copyWith(
    scaffoldBackgroundColor: kBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: kSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: kSurfaceColor,
      selectedItemColor: kAccentColor,
      unselectedItemColor: Colors.white60,
      type: BottomNavigationBarType.fixed,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kAccentColor,
    ),
    dividerColor: Colors.white24,
  );
}
