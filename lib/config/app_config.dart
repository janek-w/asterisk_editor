/// Centralized configuration for the Asterisk Editor application.
///
/// This class provides a single source of truth for all application-wide
/// constants, making it easy to adjust settings and maintain consistency
/// across the codebase.
library;

import 'package:flutter/material.dart';

/// Centralized application configuration.
///
/// Contains all constants for UI, performance, file operations, and editor behavior.
/// Using this class ensures consistency and makes global changes easier.
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // ============================================
  // UI Constants
  // ============================================

  /// Default font size for text content
  static const double defaultFontSize = 16.0;

  /// Font size for toolbar icons
  static const double toolbarIconSize = 20.0;

  /// Font size for list items
  static const double listItemFontSize = 14.0;

  /// Thickness of divider lines
  static const double dividerThickness = 1.0;

  /// Indent for divider lines
  static const double dividerIndent = 3.0;

  /// End indent for divider lines
  static const double dividerEndIndent = 3.0;

  /// Thickness for resizable dividers in split view
  static const double resizableDividerThickness = 50.0;

  // ============================================
  // Padding Constants
  // ============================================

  /// Default padding value used throughout the app
  static const double defaultPadding = 8.0;

  /// Padding for editor panes
  static const double editorPadding = 4.0;

  /// Padding for toolbar
  static const double toolbarPadding = 4.0;

  /// Padding for file browser
  static const double fileBrowserPadding = 8.0;

  /// Padding for action buttons
  static const double actionButtonPadding = 16.0;

  /// Minimum width for split view areas
  static const double splitViewMinWidth = 0.1;

  // ============================================
  // Performance Constants
  // ============================================

  /// Debounce duration for text changes during typing
  ///
  /// This prevents excessive parsing and state updates while the user
  /// is typing quickly.
  static const Duration typingDebounce = Duration(milliseconds: 150);

  /// Debounce duration for save operations
  static const Duration saveDebounce = Duration(milliseconds: 500);

  /// Debounce duration for file browser operations
  static const Duration fileBrowserDebounce = Duration(milliseconds: 300);

  /// Maximum number of tokens to cache for markdown parsing
  static const int markdownParserCacheSize = 10;

  /// Maximum pool size for TextSpan objects
  static const int textSpanPoolSize = 50;

  // ============================================
  // File Browser Constants
  // ============================================

  /// Maximum number of files to cache in file browser
  static const int fileBrowserCacheSize = 100;

  /// Supported file extensions for the editor
  static const List<String> supportedExtensions = ['.md', '.markdown', '.txt'];

  /// Maximum depth for directory traversal
  static const int maxDirectoryDepth = 10;

  /// Whether to show hidden files (starting with '.')
  static const bool showHiddenFiles = false;

  // ============================================
  // Editor Constants
  // ============================================

  /// Maximum number of undo/redo history entries
  static const int maxUndoHistory = 50;

  /// Auto-save interval in minutes
  static const int autoSaveIntervalMinutes = 5;

  /// Maximum file size to load (in bytes) - 10MB
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Maximum line length before wrapping
  static const int maxLineLength = 120;

  /// Default tab width in spaces
  static const int tabWidth = 2;

  // ============================================
  // Markdown Constants
  // ============================================

  /// Enable hidden syntax rendering (Notion/Typora style)
  ///
  /// When true, markdown syntax characters are hidden visually
  /// and only formatted content is displayed. When false, syntax
  /// is shown but styled subtly.
  ///
  /// Set to false initially for gradual rollout
  static const bool enableHiddenSyntax = false;

  /// Maximum header level (H1-H6)
  static const int maxHeaderLevel = 6;

  /// Minimum header level
  static const int minHeaderLevel = 1;

  /// Default header font size multiplier for H1
  static const double headerH1Multiplier = 2.0;

  /// Default header font size multiplier for H2
  static const double headerH2Multiplier = 1.75;

  /// Default header font size multiplier for H3
  static const double headerH3Multiplier = 1.5;

  /// Default header font size multiplier for H4
  static const double headerH4Multiplier = 1.25;

  /// Default header font size multiplier for H5
  static const double headerH5Multiplier = 1.1;

  /// Default header font size multiplier for H6
  static const double headerH6Multiplier = 1.0;

  /// Code block background color (light theme)
  static const Color codeBackgroundColorLight = Color(0xFFE0E0E0);

  /// Code block background color (dark theme)
  static const Color codeBackgroundColorDark = Color(0xFF2D2D2D);

  /// Default link color (light theme)
  static const Color linkColorLight = Colors.blue;

  /// Default link color (dark theme)
  static const Color linkColorDark = Colors.lightBlue;

  /// Syntax text color (gray, subtle)
  static const Color syntaxTextColor = Color(0xFF757575);

  /// Syntax font size multiplier (smaller than base)
  static const double syntaxFontSizeMultiplier = 0.85;

  // ============================================
  // Split View Constants
  // ============================================

  /// Default flex for file browser pane
  static const double fileBrowserFlex = 0.2;

  /// Default flex for editor pane (split view)
  static const double editorPaneFlex = 0.4;

  /// Default flex for preview pane (split view)
  static const double previewPaneFlex = 0.4;

  /// Default flex for editor pane (single view)
  static const double editorPaneSingleFlex = 0.8;

  /// Default flex for preview pane (single view)
  static const double previewPaneSingleFlex = 0.8;

  // ============================================
  // Animation Constants
  // ============================================

  /// Duration for fade animations
  static const Duration fadeAnimationDuration = Duration(milliseconds: 200);

  /// Duration for slide animations
  static const Duration slideAnimationDuration = Duration(milliseconds: 250);

  /// Duration for scale animations
  static const Duration scaleAnimationDuration = Duration(milliseconds: 150);

  /// Curve for standard animations
  static const Curve defaultAnimationCurve = Curves.easeInOut;

  /// Curve for entering animations
  static const Curve enterAnimationCurve = Curves.easeOut;

  /// Curve for exiting animations
  static const Curve exitAnimationCurve = Curves.easeIn;

  // ============================================
  // Accessibility Constants
  // ============================================

  /// Minimum touch target size for buttons
  static const double minTouchTargetSize = 44.0;

  /// Minimum contrast ratio for text
  static const double minContrastRatio = 4.5;

  /// Duration for screen reader announcements
  static const Duration screenReaderAnnouncementDelay = Duration(milliseconds: 100);

  // ============================================
  // Logging Constants
  // ============================================

  /// Maximum number of log entries to keep in memory
  static const int maxLogEntries = 1000;

  /// Whether to enable debug logging in release builds
  static const bool enableReleaseLogging = false;

  /// Whether to log to file
  static const bool enableFileLogging = true;

  /// Maximum log file size in bytes (5MB)
  static const int maxLogFileSize = 5 * 1024 * 1024;

  // ============================================
  // Network Constants (for future use)
  // ============================================

  /// Timeout for network requests
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Maximum number of retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);

  // ============================================
  // Helper Methods
  // ============================================

  /// Get header font size multiplier for a given level
  static double getHeaderMultiplier(int level) {
    switch (level) {
      case 1:
        return headerH1Multiplier;
      case 2:
        return headerH2Multiplier;
      case 3:
        return headerH3Multiplier;
      case 4:
        return headerH4Multiplier;
      case 5:
        return headerH5Multiplier;
      case 6:
        return headerH6Multiplier;
      default:
        return headerH1Multiplier;
    }
  }

  /// Check if a file extension is supported
  static bool isSupportedExtension(String fileName) {
    return supportedExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get the appropriate code background color based on theme brightness
  static Color getCodeBackgroundColor(bool isDark) {
    return isDark ? codeBackgroundColorDark : codeBackgroundColorLight;
  }

  /// Get the appropriate link color based on theme brightness
  static Color getLinkColor(bool isDark) {
    return isDark ? linkColorDark : linkColorLight;
  }
}
