// lib/theme/app_themes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/misc/no_animation_transition.dart';

class AppThemes {
  /// One seed to rule them all (Material 3).
  static const _seed = Color(0xFF3564FF);

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base);
  }

  static ThemeData light = _buildTheme(Brightness.light);
  static ThemeData dark = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: _buildTextTheme(
        brightness == Brightness.light
            ? ThemeData.light().textTheme
            : ThemeData.dark().textTheme,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Component Themes
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
        },
      ),
    );
  }
}
