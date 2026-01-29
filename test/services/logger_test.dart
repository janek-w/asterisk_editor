import 'package:flutter_test/flutter_test.dart';
import 'package:asterisk_editor/services/logger.dart';

void main() {
  // Get singleton instance once for all tests
  final logger = AppLogger();

  setUpAll(() async {
    // Clear any existing logs before tests
    logger.clearLogs();
  });

  group('AppLogger', () {
    test('returns singleton instance', () {
      final logger1 = AppLogger();
      final logger2 = AppLogger();

      expect(identical(logger1, logger2), true);
    });

    test('logs debug messages', () {
      logger.clearLogs();
      logger.debug('Test debug message');

      expect(logger.logs.isNotEmpty, true);
      expect(logger.logs.last.level, LogLevel.debug);
      expect(logger.logs.last.message, 'Test debug message');
    });

    test('logs info messages', () {
      logger.clearLogs();
      logger.info('Test info message');

      expect(logger.logs.last.level, LogLevel.info);
      expect(logger.logs.last.message, 'Test info message');
    });

    test('logs warning messages', () {
      logger.clearLogs();
      logger.warning('Test warning message');

      expect(logger.logs.last.level, LogLevel.warning);
      expect(logger.logs.last.message, 'Test warning message');
    });

    test('logs error messages', () {
      logger.clearLogs();
      logger.error('Test error message');

      expect(logger.logs.last.level, LogLevel.error);
      expect(logger.logs.last.message, 'Test error message');
    });

    test('logs with tag', () {
      logger.clearLogs();
      const testTag = 'TestTag';
      logger.info('Message with tag', tag: testTag);

      expect(logger.logs.last.tag, testTag);
    });

    test('respects minimum log level', () {
      logger.clearLogs();
      logger.setMinLevel(LogLevel.warning);

      logger.debug('Should not log');
      logger.info('Should not log');
      logger.warning('Should log');
      logger.error('Should log');

      final debugLogs = logger.getLogsByLevel(LogLevel.debug);
      final infoLogs = logger.getLogsByLevel(LogLevel.info);
      final warningLogs = logger.getLogsByLevel(LogLevel.warning);
      final errorLogs = logger.getLogsByLevel(LogLevel.error);

      expect(debugLogs.length, 0);
      expect(infoLogs.length, 0);
      expect(warningLogs.length, 1);
      expect(errorLogs.length, 1);

      // Reset to debug level for other tests
      logger.setMinLevel(LogLevel.debug);
    });

    test('exports logs to string', () {
      logger.clearLogs();
      logger.info('Export test message');

      final exported = logger.exportLogs();

      expect(exported.contains('Export test message'), true);
    });

    test('clears logs', () {
      logger.info('Message to clear');
      expect(logger.logs.isNotEmpty, true);

      logger.clearLogs();

      expect(logger.logs.isEmpty, true);
    });

    test('filters logs by level', () {
      logger.clearLogs();
      logger.debug('Debug 1');
      logger.info('Info 1');
      logger.error('Error 1');

      final errorLogs = logger.getLogsByLevel(LogLevel.error);

      expect(errorLogs.length, 1);
      expect(errorLogs.first.message, 'Error 1');
    });

    test('filters logs by tag', () {
      logger.clearLogs();
      logger.info('Message 1', tag: 'Tag1');
      logger.info('Message 2', tag: 'Tag2');
      logger.info('Message 3', tag: 'Tag1');

      final tag1Logs = logger.getLogsByTag('Tag1');

      expect(tag1Logs.length, 2);
    });
  });

  group('LogEntry', () {
    test('converts to formatted string', () {
      final now = DateTime.now();
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'Test message',
        timestamp: now,
      );

      final formatted = entry.toFormattedString();

      expect(formatted.contains('INFO'), true);
      expect(formatted.contains('Test message'), true);
      expect(formatted.contains(now.toIso8601String()), true);
    });

    test('converts to compact string', () {
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Error message',
        timestamp: DateTime.now(),
        tag: 'TestTag',
      );

      final compact = entry.toCompactString();

      expect(compact, '[ERROR] TestTag: Error message');
    });
  });

  group('TaggedAppLogger', () {
    test('logs with default tag', () {
      logger.clearLogs();
      const tag = 'ComponentTag';
      final taggedLogger = TaggedAppLogger(tag);

      taggedLogger.info('Tagged message');

      final logs = logger.getLogsByTag(tag);
      expect(logs.isNotEmpty, true);
      expect(logs.last.message, 'Tagged message');
    });
  });
}

