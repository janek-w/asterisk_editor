// lib/theme/app_themes.dart
import 'package:flutter/material.dart';
import 'package:notesapp/misc/no_animation_transition.dart';

class AppThemes {
  /// One seed to rule them all (Material 3).
  static const _seed = Color(0xFF3564FF);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
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

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
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
