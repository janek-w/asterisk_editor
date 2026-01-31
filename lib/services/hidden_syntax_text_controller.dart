/// Custom text controller with hidden markdown syntax support.
///
/// This controller extends TextEditingController to provide hidden syntax
/// rendering similar to Notion or Typora. Markdown syntax characters are
/// hidden visually while maintaining correct cursor positioning through
/// position mapping.
///
/// Example:
/// - Raw text: `**bold**`
/// - Visual text: `bold` (with bold styling)
/// - Cursor position is automatically translated between coordinate systems
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'markdown_parser.dart';
import 'position_mapper.dart';
import 'text_span_renderer.dart';

/// Custom TextEditingController that supports hidden markdown syntax.
class HiddenSyntaxTextController extends TextEditingController {
  /// Parser for markdown syntax
  final MarkdownParser parser;

  /// Renderer for creating styled TextSpans
  TextSpanRenderer renderer;

  /// Position mapper for translating between visual and raw positions
  final PositionMapper positionMapper;

  /// Whether to show raw markdown (syntax visible) or hide syntax
  bool showRawMarkdown;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Cached tokens from the last parse
  List<MarkdownToken> _cachedTokens = [];

  HiddenSyntaxTextController({
    required this.parser,
    required this.renderer,
    required this.positionMapper,
    String text = '',
    this.showRawMarkdown = false,
    this.onChanged,
  }) : super(text: text) {
    // Initial parse
    _updatePositionMapping();
  }

  @override
  set value(TextEditingValue newValue) {
    // Check if we need to map the selection
    if (!showRawMarkdown) {
      final mappedSelection = _mapSelectionFromVisual(newValue.selection);
      final mappedValue = TextEditingValue(
        text: newValue.text,
        selection: mappedSelection,
        composing: _mapRangeFromVisual(newValue.composing),
      );
      super.value = mappedValue;
    } else {
      super.value = newValue;
    }

    // Update position mapping when text changes
    _updatePositionMapping();

    // Notify callback
    onChanged?.call(newValue.text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;

    if (text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    // Parse text to get markdown tokens
    final tokens = parser.parseText(text);
    _cachedTokens = tokens;

    // Update position mapping
    if (!showRawMarkdown) {
      positionMapper.rebuild(text, tokens);
    }

    // Build the appropriate TextSpan based on mode
    final baseTextStyle = style ?? const TextStyle();
    if (showRawMarkdown) {
      return renderer.buildTextSpanWithVisibleSyntax(text, tokens, baseTextStyle);
    } else {
      return renderer.buildTextSpanWithHiddenSyntax(text, tokens, baseTextStyle);
    }
  }

  /// Toggle between raw markdown and hidden syntax mode.
  ///
  /// Returns the new state (true = raw markdown visible)
  bool toggleSyntaxVisibility() {
    showRawMarkdown = !showRawMarkdown;
    _updatePositionMapping();
    notifyListeners();
    return showRawMarkdown;
  }

  /// Set the syntax visibility mode.
  void setSyntaxVisibility(bool showRaw) {
    if (showRawMarkdown != showRaw) {
      showRawMarkdown = showRaw;
      _updatePositionMapping();
      notifyListeners();
    }
  }

  /// Convert a visual selection to a raw selection.
  ///
  /// When syntax is hidden, the visual cursor position doesn't match
  /// the raw text position. This method translates the selection.
  TextSelection _mapSelectionFromVisual(TextSelection visualSelection) {
    if (showRawMarkdown || !visualSelection.isValid) {
      return visualSelection;
    }

    final baseOffset = positionMapper.visualToRaw(visualSelection.baseOffset);
    final extentOffset = positionMapper.visualToRaw(visualSelection.extentOffset);

    return TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: visualSelection.affinity,
      isDirectional: visualSelection.isDirectional,
    );
  }

  /// Convert a raw selection to a visual selection.
  ///
  /// This is the inverse of _mapSelectionFromVisual.
  TextSelection _mapSelectionToRaw(TextSelection rawSelection) {
    if (showRawMarkdown || !rawSelection.isValid) {
      return rawSelection;
    }

    final baseOffset = positionMapper.rawToVisual(rawSelection.baseOffset);
    final extentOffset = positionMapper.rawToVisual(rawSelection.extentOffset);

    return TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: rawSelection.affinity,
      isDirectional: rawSelection.isDirectional,
    );
  }

  /// Convert a visual text range to a raw text range.
  TextRange _mapRangeFromVisual(TextRange visualRange) {
    if (showRawMarkdown || !visualRange.isValid) {
      return visualRange;
    }

    final start = positionMapper.visualToRaw(visualRange.start);
    final end = positionMapper.visualToRaw(visualRange.end);

    return TextRange(start: start, end: end);
  }

  /// Convert a raw text range to a visual text range.
  TextRange _mapRangeToRaw(TextRange rawRange) {
    if (showRawMarkdown || !rawRange.isValid) {
      return rawRange;
    }

    final start = positionMapper.rawToVisual(rawRange.start);
    final end = positionMapper.rawToVisual(rawRange.end);

    return TextRange(start: start, end: end);
  }

  /// Get the visual position for a given raw position.
  ///
  /// Useful for positioning cursors or selections.
  int rawToVisualPosition(int rawPosition) {
    if (showRawMarkdown) {
      return rawPosition;
    }
    return positionMapper.rawToVisual(rawPosition);
  }

  /// Get the raw position for a given visual position.
  ///
  /// Useful when handling tap events or user interactions.
  int visualToRawPosition(int visualPosition) {
    if (showRawMarkdown) {
      return visualPosition;
    }
    return positionMapper.visualToRaw(visualPosition);
  }

  /// Check if a raw position is within hidden syntax.
  bool isPositionHidden(int rawPosition) {
    if (showRawMarkdown) {
      return false;
    }
    return positionMapper.isPositionHidden(rawPosition);
  }

  /// Get the nearest visible position to a raw position.
  ///
  /// Useful for snapping the cursor to visible content when
  /// the user clicks on hidden syntax.
  int getNearestVisiblePosition(int rawPosition) {
    if (showRawMarkdown) {
      return rawPosition;
    }
    return positionMapper.getNearestVisiblePosition(rawPosition);
  }

  /// Update the position mapping based on current text and tokens.
  void _updatePositionMapping() {
    if (!showRawMarkdown) {
      final tokens = parser.parseText(text);
      positionMapper.rebuild(text, tokens);
    } else {
      positionMapper.clear();
    }
  }

  /// Get the cached tokens from the last parse.
  List<MarkdownToken> get cachedTokens => List.unmodifiable(_cachedTokens);

  /// Handle text input with automatic syntax insertion.
  ///
  /// This method can be used to insert markdown syntax at the current
  /// cursor position with proper handling of the selection.
  void insertMarkdownSyntax(String prefix, String suffix) {
    final selection = this.selection;
    final text = this.text;

    if (!selection.isValid) return;

    final selectedText = selection.isCollapsed
        ? ''
        : text.substring(selection.start, selection.end);

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );

    final newCursorOffset = selection.start + prefix.length + selectedText.length;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, newText.length),
      ),
    );
  }

  /// Toggle a markdown format at the current selection.
  ///
  /// If the selection is already formatted with the given syntax,
  /// this removes the formatting. Otherwise, it adds it.
  void toggleMarkdownFormat(String formatChars) {
    final selection = this.selection;
    final text = this.text;

    if (!selection.isValid || selection.isCollapsed) {
      // Just insert the format
      insertMarkdownSyntax(formatChars, formatChars);
      return;
    }

    final selectedText = text.substring(selection.start, selection.end);

    // Check if the selection is already wrapped in the format
    if (selection.start >= formatChars.length &&
        selection.end + formatChars.length <= text.length) {
      final beforeFormat = text.substring(
        selection.start - formatChars.length,
        selection.start,
      );
      final afterFormat = text.substring(
        selection.end,
        selection.end + formatChars.length,
      );

      if (beforeFormat == formatChars && afterFormat == formatChars) {
        // Remove the format
        final newText = text.replaceRange(
          selection.end,
          selection.end + formatChars.length,
          '',
        ).replaceRange(
          selection.start - formatChars.length,
          selection.start,
          '',
        );

        value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: selection.start - formatChars.length,
            extentOffset: selection.end - formatChars.length,
          ),
        );
        return;
      }
    }

    // Add the format
    insertMarkdownSyntax(formatChars, formatChars);
  }

  @override
  void dispose() {
    // PositionMapper is not owned by this controller, so don't dispose it
    // Renderer is also not owned by this controller
    super.dispose();
  }
}
