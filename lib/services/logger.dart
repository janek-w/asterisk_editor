/// Centralized logging service for the Asterisk Editor application.
///
/// Provides a consistent logging mechanism with different log levels,
/// log history tracking, and support for both console and file logging.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Log severity levels.
enum LogLevel {
  /// Debug information for development purposes
  debug,

  /// General informational messages
  info,

  /// Warning messages for potential issues
  warning,

  /// Error messages for failures and exceptions
  error,
}

/// Represents a single log entry with all relevant information.
class LogEntry {
  /// The severity level of this log entry
  final LogLevel level;

  /// The log message
  final String message;

  /// Optional error object associated with this log entry
  final Object? error;

  /// Optional stack trace associated with this log entry
  final StackTrace? stackTrace;

  /// Timestamp when this log entry was created
  final DateTime timestamp;

  /// Optional tag/category for grouping logs
  final String? tag;

  const LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
    this.tag,
  });

  /// Convert this log entry to a formatted string
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}]');
    if (tag != null) {
      buffer.write(' [$tag]');
    }
    buffer.write(' $message');
    
    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    
    if (stackTrace != null) {
      buffer.write('\n  StackTrace:\n$stackTrace');
    }
    
    return buffer.toString();
  }

  /// Convert this log entry to a compact string (for console output)
  String toCompactString() {
    final buffer = StringBuffer();
    buffer.write('[${level.name.toUpperCase()}] ');
    if (tag != null) {
      buffer.write('$tag: ');
    }
    buffer.write(message);
    return buffer.toString();
  }

  @override
  String toString() => toFormattedString();
}

/// Centralized logging service for the application.
///
/// This singleton provides:
/// - Multiple log levels (debug, info, warning, error)
/// - Log history tracking in memory
/// - Stream of log entries for real-time monitoring
/// - Console output in debug mode
/// - Optional file logging
/// - Tag-based log filtering
class AppLogger {
  /// Private constructor for singleton pattern
  AppLogger._internal();

  /// Singleton instance
  static final AppLogger _instance = AppLogger._internal();

  /// Get the singleton instance
  factory AppLogger() => _instance;

  /// In-memory log history
  final List<LogEntry> _logs = [];

  /// Stream controller for broadcasting log entries
  final StreamController<LogEntry> _logController = StreamController.broadcast();

  /// File for persistent logging
  File? _logFile;

  /// Current minimum log level (logs below this level are ignored)
  LogLevel _minLevel = LogLevel.debug;

  /// Get the stream of log entries for real-time monitoring
  Stream<LogEntry> get logStream => _logController.stream;

  /// Get all logged entries (up to max limit)
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Get the current minimum log level
  LogLevel get minLevel => _minLevel;

  /// Set the minimum log level
  ///
  /// Logs with a level lower than [level] will be ignored.
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Initialize the logger with optional file logging
  ///
  /// [logFilePath] - Optional path to the log file. If null, file logging is disabled.
  Future<void> initialize({String? logFilePath}) async {
    if (logFilePath != null && AppConfig.enableFileLogging) {
      try {
        _logFile = File(logFilePath);
        // Create parent directories if they don't exist
        await _logFile!.parent.create(recursive: true);
        
        // Check file size and rotate if necessary
        if (await _logFile!.exists()) {
          final size = await _logFile!.length();
          if (size > AppConfig.maxLogFileSize) {
            await _rotateLogFile();
          }
        }
      } catch (e) {
        // Don't fail initialization if file logging setup fails
        debug('Failed to initialize file logging: $e');
      }
    }
  }

  /// Log a debug message
  ///
  /// [message] - The message to log
  /// [tag] - Optional tag/category for the log entry
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  ///
  /// [message] - The message to log
  /// [tag] - Optional tag/category for the log entry
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  ///
  /// [message] - The message to log
  /// [tag] - Optional tag/category for the log entry
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  ///
  /// [message] - The message to log
  /// [tag] - Optional tag/category for the log entry
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an exception with automatic stack trace capture
  ///
  /// [message] - The message to log
  /// [exception] - The exception that occurred
  /// [tag] - Optional tag/category for the log entry
  /// [stackTrace] - Optional stack trace (captured automatically if not provided)
  void exception(
    String message,
    Object exception, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: exception,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if this log level should be logged
    if (level.index < _minLevel.index) {
      return;
    }

    // Create the log entry
    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      tag: tag,
    );

    // Add to in-memory history
    _logs.add(entry);
    
    // Enforce max log limit
    if (_logs.length > AppConfig.maxLogEntries) {
      _logs.removeAt(0);
    }

    // Broadcast to stream listeners
    _logController.add(entry);

    // Print to console in debug mode
    if (kDebugMode || (kReleaseMode && AppConfig.enableReleaseLogging)) {
      print(entry.toCompactString());
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null && level == LogLevel.error) {
        print('  StackTrace:\n$stackTrace');
      }
    }

    // Write to log file if enabled
    if (_logFile != null) {
      _writeToFile(entry);
    }
  }

  /// Write log entry to file
  void _writeToFile(LogEntry entry) {
    try {
      _logFile!.writeAsStringSync(
        '${entry.toFormattedString()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Don't recursively log file write errors
      print('Failed to write to log file: $e');
    }
  }

  /// Rotate log file when it gets too large
  Future<void> _rotateLogFile() async {
    if (_logFile == null) return;
    
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final rotatedFile = File('${_logFile!.path}.$timestamp');
      await _logFile!.rename(rotatedFile.path);
    } catch (e) {
      print('Failed to rotate log file: $e');
    }
  }

  /// Clear all in-memory log entries
  void clearLogs() {
    _logs.clear();
  }

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((entry) => entry.level == level).toList();
  }

  /// Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((entry) => entry.tag == tag).toList();
  }

  /// Get logs within a time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs.where((entry) {
      return entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end);
    }).toList();
  }

  /// Export logs to a string
  String exportLogs() {
    return _logs.map((entry) => entry.toFormattedString()).join('\n');
  }

  /// Export logs to a file
  Future<void> exportLogsToFile(String filePath) async {
    final file = File(filePath);
    await file.writeAsString(exportLogs());
  }

  /// Dispose of the logger and close resources
  Future<void> dispose() async {
    await _logController.close();
  }
}

/// Convenience extension for getting a tagged logger
extension TaggedLogger on AppLogger {
  /// Create a logger that automatically uses the specified tag
  TaggedAppLogger withTag(String tag) {
    return TaggedAppLogger(tag);
  }
}

/// A logger that automatically applies a tag to all log messages.
///
/// This class wraps the main [AppLogger] and adds a default tag
/// to every log message, making it easier to categorize logs by component.
class TaggedAppLogger {
  final String _tag;

  TaggedAppLogger(this._tag);

  /// Log a debug message with the default tag
  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger().debug(message, tag: _tag, error: error, stackTrace: stackTrace);
  }

  /// Log an info message with the default tag
  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger().info(message, tag: _tag, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message with the default tag
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger().warning(message, tag: _tag, error: error, stackTrace: stackTrace);
  }

  /// Log an error message with the default tag
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger().error(message, tag: _tag, error: error, stackTrace: stackTrace);
  }

  /// Log an exception with the default tag
  void exception(
    String message,
    Object exception, {
    StackTrace? stackTrace,
  }) {
    AppLogger().exception(message, exception, tag: _tag, stackTrace: stackTrace);
  }
}
