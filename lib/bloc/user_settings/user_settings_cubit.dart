// lib/settings/user_settings_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/misc/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsCubit extends Cubit<UserSettings> {
  final SharedPreferences _prefs;

  UserSettingsCubit(this._prefs) : super(UserSettings.fallback) {
    _hydrate(); // Load on start‑up
  }

  /* ----------  Public API  ---------- */

  void toggleTheme() {
    final next = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _update(state.copyWith(themeMode: next));
  }

  void setLocale(String code) => _update(state.copyWith(localeCode: code));

  void setTheme(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

  void enableNotifications(bool flag) =>
      _update(state.copyWith(notificationsEnabled: flag));

  /* ----------  Private helpers  ---------- */

  Future<void> _hydrate() async {
    emit(UserSettings(
      themeMode: ThemeMode.values[_prefs.getInt('themeMode') ?? 0],
      localeCode: _prefs.getString('localeCode') ?? 'en',
      notificationsEnabled: _prefs.getBool('notifications') ?? true,
    ));
  }

  Future<void> _update(UserSettings next) async {
    await Future.wait([
      _prefs.setInt('themeMode', next.themeMode.index),
      _prefs.setString('localeCode', next.localeCode),
      _prefs.setBool('notifications', next.notificationsEnabled),
    ]);
    emit(next);
  }
}
