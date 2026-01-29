import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asterisk_editor/bloc/user_settings/user_settings_cubit.dart';
import 'package:asterisk_editor/misc/user_settings.dart';

void main() {
  group('UserSettingsCubit', () {
    late SharedPreferences prefs;
    late UserSettingsCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cubit = UserSettingsCubit(prefs);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is UserSettings.fallback', () {
      expect(cubit.state, UserSettings.fallback);
    });

    test('toggleTheme switches between light and dark', () async {
      final initialMode = cubit.state.themeMode;

      cubit.toggleTheme();
      await cubit.stream.first;

      expect(cubit.state.themeMode, isNot(initialMode));
    });

    test('setTheme updates theme mode', () async {
      cubit.setTheme(ThemeMode.dark);
      await cubit.stream.first;

      expect(cubit.state.themeMode, ThemeMode.dark);
    });

    test('setLocale updates locale code', () async {
      const testLocale = 'en_US';

      cubit.setLocale(testLocale);
      await cubit.stream.first;

      expect(cubit.state.localeCode, testLocale);
    });

    test('enableNotifications updates notifications flag', () async {
      cubit.enableNotifications(false);
      await cubit.stream.first;

      expect(cubit.state.notificationsEnabled, false);
    });

    test('persist settings across instances', () async {
      // First instance sets a value
      final firstCubit = UserSettingsCubit(prefs);
      firstCubit.setTheme(ThemeMode.dark);
      await firstCubit.stream.first;

      // Close first instance
      await firstCubit.close();

      // Second instance should read the persisted value
      final secondCubit = UserSettingsCubit(prefs);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(secondCubit.state.themeMode, ThemeMode.dark);

      await secondCubit.close();
    });
  });
}
