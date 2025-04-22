import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final ThemeMode themeMode;
  final String localeCode;
  final bool notificationsEnabled;

  const UserSettings({
    required this.themeMode,
    required this.localeCode,
    required this.notificationsEnabled,
  });

  // Default baseline
  static const fallback = UserSettings(
    themeMode: ThemeMode.system,
    localeCode: 'en',
    notificationsEnabled: true,
  );

  UserSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool? notificationsEnabled,
  }) =>
      UserSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  List<Object?> get props => [themeMode, localeCode, notificationsEnabled];
}