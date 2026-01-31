/// Cursor manager for handling cursor position with hidden syntax.
///
/// When markdown syntax is hidden, cursor position handling becomes
/// complex because the visual position no longer matches the raw text position.
/// This service provides methods to handle cursor placement and movement.
library;

import 'package:flutter/material.dart';
import 'position_mapper.dart';

/// Result of a cursor position calculation.
class CursorPositionResult {
  /// The raw text position for the cursor
  final int rawPosition;

  /// The visual position (for display purposes)
  final int visualPosition;

  /// Whether the cursor was adjusted (e.g., snapped to nearest visible)
  final bool wasAdjusted;

  /// The selection affinity (upstream or downstream)
  final TextAffinity affinity;

  const CursorPositionResult({
    required this.rawPosition,
    required this.visualPosition,
    this.wasAdjusted = false,
    this.affinity = TextAffinity.downstream,
  });

  @override
  String toString() =>
      'CursorPositionResult(raw: $rawPosition, visual: $visualPosition, adjusted: $wasAdjusted)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CursorPositionResult &&
        other.rawPosition == rawPosition &&
        other.visualPosition == visualPosition &&
        other.wasAdjusted == wasAdjusted &&
        other.affinity == affinity;
  }

  @override
  int get hashCode =>
      rawPosition.hashCode ^ visualPosition.hashCode ^ wasAdjusted.hashCode ^ affinity.hashCode;
}

/// Manager for cursor position handling with hidden syntax.
class CursorManager {
  /// Position mapper for translating between visual and raw positions
  final PositionMapper positionMapper;

  /// Whether syntax is currently hidden
  bool showRawMarkdown;

  CursorManager({
    required this.positionMapper,
    this.showRawMarkdown = false,
  });

  /// Handle a tap event at a visual position.
  ///
  /// When the user taps at a visual position, this calculates
  /// the appropriate raw cursor position.
  ///
  /// [visualPosition] The position where the user tapped (in visual coordinates)
  /// [rawText] The raw text content
  ///
  /// Returns a [CursorPositionResult] with the calculated cursor position
  CursorPositionResult handleTapAtVisualPosition(int visualPosition, String rawText) {
    if (showRawMarkdown) {
      return CursorPositionResult(
        rawPosition: visualPosition,
        visualPosition: visualPosition,
      );
    }

    // Convert visual position to raw position
    final rawPosition = positionMapper.visualToRaw(visualPosition);

    // Check if the raw position is in hidden syntax
    final isHidden = positionMapper.isPositionHidden(rawPosition);

    if (isHidden) {
      // Snap to nearest visible position
      final nearestVisible = positionMapper.getNearestVisiblePosition(rawPosition);
      final adjustedRaw = positionMapper.visualToRaw(nearestVisible);

      return CursorPositionResult(
        rawPosition: adjustedRaw,
        visualPosition: nearestVisible,
        wasAdjusted: true,
      );
    }

    return CursorPositionResult(
      rawPosition: rawPosition,
      visualPosition: visualPosition,
    );
  }

  /// Handle a long press event at a visual position.
  ///
  /// Long press typically selects a word. This method finds the
  /// word boundaries considering hidden syntax.
  ///
  /// [visualPosition] The position where the user long pressed
  /// [rawText] The raw text content
  ///
  /// Returns a [TextSelection] in raw coordinates
  TextSelection handleLongPressAtVisualPosition(int visualPosition, String rawText) {
    if (showRawMarkdown) {
      return _selectWordAt(visualPosition, rawText);
    }

    final rawPosition = positionMapper.visualToRaw(visualPosition);
    return _selectWordAt(rawPosition, rawText);
  }

  /// Handle a drag selection event.
  ///
  /// When the user drags to select text, this handles the selection
  /// boundaries considering hidden syntax.
  ///
  /// [startVisualPosition] The start position of the selection (visual)
  /// [endVisualPosition] The end position of the selection (visual)
  /// [rawText] The raw text content
  ///
  /// Returns a [TextSelection] in raw coordinates
  TextSelection handleDragSelection(
    int startVisualPosition,
    int endVisualPosition,
    String rawText,
  ) {
    if (showRawMarkdown) {
      return TextSelection(
        baseOffset: startVisualPosition,
        extentOffset: endVisualPosition,
      );
    }

    final startRaw = positionMapper.visualToRaw(startVisualPosition);
    final endRaw = positionMapper.visualToRaw(endVisualPosition);

    return TextSelection(
      baseOffset: startRaw,
      extentOffset: endRaw,
    );
  }

  /// Handle double-tap to select a word.
  ///
  /// [visualPosition] The position of the double-tap
  /// [rawText] The raw text content
  ///
  /// Returns a [TextSelection] in raw coordinates
  TextSelection handleDoubleTapAtVisualPosition(int visualPosition, String rawText) {
    // Double-tap behaves the same as long-press for word selection
    return handleLongPressAtVisualPosition(visualPosition, rawText);
  }

  /// Handle triple-tap to select a line.
  ///
  /// [visualPosition] The position of the triple-tap
  /// [rawText] The raw text content
  ///
  /// Returns a [TextSelection] in raw coordinates
  TextSelection handleTripleTapAtVisualPosition(int visualPosition, String rawText) {
    if (showRawMarkdown) {
      return _selectLineAt(visualPosition, rawText);
    }

    final rawPosition = positionMapper.visualToRaw(visualPosition);
    return _selectLineAt(rawPosition, rawText);
  }

  /// Move the cursor forward by one character.
  ///
  /// [currentRawPosition] The current cursor position in raw coordinates
  /// [rawText] The raw text content
  ///
  /// Returns the new raw cursor position
  int moveForward(int currentRawPosition, String rawText) {
    if (showRawMarkdown) {
      return (currentRawPosition + 1).clamp(0, rawText.length);
    }

    // Move to the next visible position
    final currentVisual = positionMapper.rawToVisual(currentRawPosition);
    final nextVisual = (currentVisual + 1).clamp(0, positionMapper.visualLength);
    return positionMapper.visualToRaw(nextVisual);
  }

  /// Move the cursor backward by one character.
  ///
  /// [currentRawPosition] The current cursor position in raw coordinates
  /// [rawText] The raw text content
  ///
  /// Returns the new raw cursor position
  int moveBackward(int currentRawPosition, String rawText) {
    if (showRawMarkdown) {
      return (currentRawPosition - 1).clamp(0, rawText.length);
    }

    // Move to the previous visible position
    final currentVisual = positionMapper.rawToVisual(currentRawPosition);
    final prevVisual = (currentVisual - 1).clamp(0, positionMapper.visualLength);
    return positionMapper.visualToRaw(prevVisual);
  }

  /// Move the cursor to the next word boundary.
  ///
  /// [currentRawPosition] The current cursor position in raw coordinates
  /// [rawText] The raw text content
  ///
  /// Returns the new raw cursor position
  int moveWordForward(int currentRawPosition, String rawText) {
    if (showRawMarkdown) {
      return _findNextWordBoundary(currentRawPosition, rawText);
    }

    final currentVisual = positionMapper.rawToVisual(currentRawPosition);
    final nextWordVisual = _findNextWordBoundary(currentVisual, _getVisualText(rawText));
    return positionMapper.visualToRaw(nextWordVisual);
  }

  /// Move the cursor to the previous word boundary.
  ///
  /// [currentRawPosition] The current cursor position in raw coordinates
  /// [rawText] The raw text content
  ///
  /// Returns the new raw cursor position
  int moveWordBackward(int currentRawPosition, String rawText) {
    if (showRawMarkdown) {
      return _findPreviousWordBoundary(currentRawPosition, rawText);
    }

    final currentVisual = positionMapper.rawToVisual(currentRawPosition);
    final prevWordVisual = _findPreviousWordBoundary(currentVisual, _getVisualText(rawText));
    return positionMapper.visualToRaw(prevWordVisual);
  }

  /// Get the visual text (without hidden syntax).
  String _getVisualText(String rawText) {
    final buffer = StringBuffer();
    for (final segment in positionMapper.segments) {
      buffer.write(segment.visibleText);
    }
    return buffer.toString();
  }

  /// Select the word at the given position.
  TextSelection _selectWordAt(int position, String text) {
    if (text.isEmpty || position < 0 || position >= text.length) {
      return TextSelection.collapsed(offset: position.clamp(0, text.length));
    }

    // Find word boundaries
    int start = position;
    int end = position;

    // Move start backward to find word boundary
    while (start > 0 && _isWordCharacter(text[start - 1])) {
      start--;
    }

    // Move end forward to find word boundary
    while (end < text.length && _isWordCharacter(text[end])) {
      end++;
    }

    return TextSelection(baseOffset: start, extentOffset: end);
  }

  /// Select the line at the given position.
  TextSelection _selectLineAt(int position, String text) {
    if (text.isEmpty) {
      return const TextSelection.collapsed(offset: 0);
    }

    final clampedPosition = position.clamp(0, text.length - 1);

    // Find line start
    int start = clampedPosition;
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }

    // Find line end
    int end = clampedPosition;
    while (end < text.length && text[end] != '\n') {
      end++;
    }

    return TextSelection(baseOffset: start, extentOffset: end);
  }

  /// Find the next word boundary.
  int _findNextWordBoundary(int position, String text) {
    if (position >= text.length) return text.length;

    // Skip non-word characters
    while (position < text.length && !_isWordCharacter(text[position])) {
      position++;
    }

    // Skip word characters
    while (position < text.length && _isWordCharacter(text[position])) {
      position++;
    }

    return position;
  }

  /// Find the previous word boundary.
  int _findPreviousWordBoundary(int position, String text) {
    if (position <= 0) return 0;

    // Skip word characters
    while (position > 0 && _isWordCharacter(text[position - 1])) {
      position--;
    }

    // Skip non-word characters
    while (position > 0 && !_isWordCharacter(text[position - 1])) {
      position--;
    }

    return position;
  }

  /// Check if a character is a word character (letter, digit, or underscore).
  bool _isWordCharacter(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnitAt(0);
    // Check for letters, digits, and underscore
    return (codeUnit >= 48 && codeUnit <= 57) || // 0-9
        (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122) || // a-z
        codeUnit == 95; // _
  }

  /// Update the raw markdown mode.
  void setShowRawMarkdown(bool showRaw) {
    showRawMarkdown = showRaw;
  }

  /// Check if a raw position is within hidden syntax.
  ///
  /// [rawPosition] Position in the raw text
  /// Returns true if the position is within hidden syntax characters
  bool isPositionHidden(int rawPosition) {
    if (showRawMarkdown) return false;
    return positionMapper.isPositionHidden(rawPosition);
  }

  /// Get the nearest visible position to a raw position.
  ///
  /// [rawPosition] Position in the raw text
  /// Returns the nearest position in visible text
  int getNearestVisiblePosition(int rawPosition) {
    if (showRawMarkdown) return rawPosition;
    return positionMapper.getNearestVisiblePosition(rawPosition);
  }
}
