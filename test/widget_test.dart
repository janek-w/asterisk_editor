// Basic Flutter widget tests for the Asterisk Editor application.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asterisk_editor/main.dart';
import 'package:asterisk_editor/pages/main_page/main_page.dart';

void main() {
  group('AsteriskEditor App Tests', () {
    setUp(() {
      // Setup SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App initializes without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(AsteriskEditor(
        initialPath: '.',
        prefs: prefs,
      ));

      // Verify that the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App displays home page', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(AsteriskEditor(
        initialPath: '.',
        prefs: prefs,
      ));

      // Verify that the home page is displayed
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('App has settings button', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(AsteriskEditor(
        initialPath: '.',
        prefs: prefs,
      ));

      // Verify settings button exists
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
