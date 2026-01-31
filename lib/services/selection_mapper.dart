/// Selection mapper for handling text selection with hidden syntax.
///
/// When markdown syntax is hidden, text selection needs to be mapped
/// between visual and raw coordinate systems. This service provides
/// methods to handle selection mapping and manipulation.
library;

import 'package:flutter/material.dart';
import 'position_mapper.dart';

/// Result of a selection mapping operation.
class SelectionMappingResult {
  /// The raw text selection
  final TextSelection rawSelection;

  /// The visual selection (for display purposes)
  final TextSelection visualSelection;

  /// Whether the selection was adjusted (e.g., to avoid hidden syntax)
  final bool wasAdjusted;

  const SelectionMappingResult({
    required this.rawSelection,
    required this.visualSelection,
    this.wasAdjusted = false,
  });

  @override
  String toString() =>
      'SelectionMappingResult(raw: $rawSelection, visual: $visualSelection, adjusted: $wasAdjusted)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectionMappingResult &&
        other.rawSelection == rawSelection &&
        other.visualSelection == visualSelection &&
        other.wasAdjusted == wasAdjusted;
  }

  @override
  int get hashCode =>
      rawSelection.hashCode ^ visualSelection.hashCode ^ wasAdjusted.hashCode;
}

/// Manager for text selection mapping with hidden syntax.
class SelectionMapper {
  /// Position mapper for translating between visual and raw positions
  final PositionMapper positionMapper;

  /// Whether syntax is currently hidden
  bool showRawMarkdown;

  SelectionMapper({
    required this.positionMapper,
    this.showRawMarkdown = false,
  });

  /// Map a visual selection to a raw selection.
  ///
  /// [visualSelection] The selection in visual coordinates
  ///
  /// Returns a [SelectionMappingResult] with both raw and visual selections
  SelectionMappingResult mapVisualToRaw(TextSelection visualSelection) {
    if (showRawMarkdown || !visualSelection.isValid) {
      return SelectionMappingResult(
        rawSelection: visualSelection,
        visualSelection: visualSelection,
      );
    }

    final baseOffset = positionMapper.visualToRaw(visualSelection.baseOffset);
    final extentOffset = positionMapper.visualToRaw(visualSelection.extentOffset);

    final rawSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: visualSelection.affinity,
      isDirectional: visualSelection.isDirectional,
    );

    // Check if selection was adjusted
    final wasAdjusted = baseOffset != visualSelection.baseOffset ||
        extentOffset != visualSelection.extentOffset;

    return SelectionMappingResult(
      rawSelection: rawSelection,
      visualSelection: visualSelection,
      wasAdjusted: wasAdjusted,
    );
  }

  /// Map a raw selection to a visual selection.
  ///
  /// [rawSelection] The selection in raw coordinates
  ///
  /// Returns a [SelectionMappingResult] with both raw and visual selections
  SelectionMappingResult mapRawToVisual(TextSelection rawSelection) {
    if (showRawMarkdown || !rawSelection.isValid) {
      return SelectionMappingResult(
        rawSelection: rawSelection,
        visualSelection: rawSelection,
      );
    }

    final baseOffset = positionMapper.rawToVisual(rawSelection.baseOffset);
    final extentOffset = positionMapper.rawToVisual(rawSelection.extentOffset);

    final visualSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: rawSelection.affinity,
      isDirectional: rawSelection.isDirectional,
    );

    // Check if selection was adjusted
    final wasAdjusted = baseOffset != rawSelection.baseOffset ||
        extentOffset != rawSelection.extentOffset;

    return SelectionMappingResult(
      rawSelection: rawSelection,
      visualSelection: visualSelection,
      wasAdjusted: wasAdjusted,
    );
  }

  /// Extend a selection to include more text.
  ///
  /// [selection] The current selection (in raw coordinates)
  /// [extendBase] Whether to extend the base offset (false = extend extent)
  /// [count] Number of characters to extend (positive = forward, negative = backward)
  /// [maxLength] Maximum length of the text
  ///
  /// Returns the new selection in raw coordinates
  TextSelection extendSelection(
    TextSelection selection,
    bool extendBase,
    int count,
    int maxLength,
  ) {
    if (showRawMarkdown) {
      return _extendSelectionRaw(selection, extendBase, count, maxLength);
    }

    // Convert to visual, extend, then convert back
    final visualBase = positionMapper.rawToVisual(selection.baseOffset);
    final visualExtent = positionMapper.rawToVisual(selection.extentOffset);

    final visualToExtend = extendBase ? visualBase : visualExtent;
    final newVisualOffset = (visualToExtend + count).clamp(0, positionMapper.visualLength);

    if (extendBase) {
      final newRawBase = positionMapper.visualToRaw(newVisualOffset);
      return selection.copyWith(baseOffset: newRawBase);
    } else {
      final newRawExtent = positionMapper.visualToRaw(newVisualOffset);
      return selection.copyWith(extentOffset: newRawExtent);
    }
  }

  /// Collapse a selection to a cursor position.
  ///
  /// [selection] The current selection
  /// [toStart] Whether to collapse to the start (false = collapse to end)
  ///
  /// Returns a collapsed selection at the appropriate position
  TextSelection collapseSelection(TextSelection selection, bool toStart) {
    if (selection.isCollapsed) {
      return selection;
    }

    final offset = toStart
        ? (selection.baseOffset < selection.extentOffset
            ? selection.baseOffset
            : selection.extentOffset)
        : (selection.baseOffset > selection.extentOffset
            ? selection.baseOffset
            : selection.extentOffset);

    return TextSelection.collapsed(offset: offset);
  }

  /// Select all text.
  ///
  /// [textLength] The length of the text
  ///
  /// Returns a selection covering the entire text
  TextSelection selectAll(int textLength) {
    return TextSelection(baseOffset: 0, extentOffset: textLength);
  }

  /// Get the selected text.
  ///
  /// [selection] The selection in raw coordinates
  /// [text] The raw text
  ///
  /// Returns the selected text portion
  String getSelectedText(TextSelection selection, String text) {
    if (!selection.isValid || text.isEmpty) {
      return '';
    }

    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

    if (start >= end) {
      return '';
    }

    return text.substring(start, end);
  }

  /// Get the selected text in visual form (without hidden syntax).
  ///
  /// [selection] The selection in raw coordinates
  ///
  /// Returns the selected text with hidden syntax removed
  String getSelectedVisualText(TextSelection selection) {
    if (!selection.isValid || positionMapper.segments.isEmpty) {
      return '';
    }

    final start = selection.start;
    final end = selection.end;

    if (start >= end) {
      return '';
    }

    final buffer = StringBuffer();

    for (final segment in positionMapper.segments) {
      // Skip segments before the selection
      if (segment.rawEnd <= start) continue;

      // Stop after the selection
      if (segment.rawStart >= end) break;

      // Calculate overlap with selection
      final overlapStart = segment.rawStart.clamp(start, end);
      final overlapEnd = segment.rawEnd.clamp(start, end);

      if (overlapStart < overlapEnd) {
        // Calculate the offset within this segment
        final startOffset = overlapStart - segment.rawStart;
        final endOffset = overlapEnd - segment.rawStart;

        // Add the visible portion
        final visibleStart = startOffset.clamp(0, segment.visibleText.length);
        final visibleEnd = endOffset.clamp(0, segment.visibleText.length);

        if (visibleStart < visibleEnd) {
          buffer.write(segment.visibleText.substring(visibleStart, visibleEnd));
        }
      }
    }

    return buffer.toString();
  }

  /// Check if a selection is entirely within hidden syntax.
  ///
  /// [selection] The selection to check
  ///
  /// Returns true if the entire selection is within hidden syntax
  bool isSelectionHidden(TextSelection selection) {
    if (!selection.isValid || showRawMarkdown) {
      return false;
    }

    final start = selection.start;
    final end = selection.end;

    // Check each position in the selection
    for (int pos = start; pos < end; pos++) {
      if (!positionMapper.isPositionHidden(pos)) {
        return false;
      }
    }

    return true;
  }

  /// Check if a selection intersects with hidden syntax.
  ///
  /// [selection] The selection to check
  ///
  /// Returns true if any part of the selection is within hidden syntax
  bool doesSelectionIntersectHidden(TextSelection selection) {
    if (!selection.isValid || showRawMarkdown) {
      return false;
    }

    final start = selection.start;
    final end = selection.end;

    // Check each position in the selection
    for (int pos = start; pos < end; pos++) {
      if (positionMapper.isPositionHidden(pos)) {
        return true;
      }
    }

    return false;
  }

  /// Adjust a selection to avoid hidden syntax.
  ///
  /// If a selection includes hidden syntax, this adjusts it to
  /// only include visible content.
  ///
  /// [selection] The selection to adjust
  ///
  /// Returns the adjusted selection in raw coordinates
  TextSelection adjustSelectionToVisible(TextSelection selection) {
    if (!selection.isValid || showRawMarkdown) {
      return selection;
    }

    final start = selection.start;
    final end = selection.end;

    // Find the first visible position
    int adjustedStart = start;
    while (adjustedStart < end && positionMapper.isPositionHidden(adjustedStart)) {
      adjustedStart++;
    }

    // Find the last visible position
    int adjustedEnd = end;
    while (adjustedEnd > adjustedStart && positionMapper.isPositionHidden(adjustedEnd - 1)) {
      adjustedEnd--;
    }

    if (adjustedStart >= adjustedEnd) {
      // Entire selection is hidden, collapse to nearest visible
      final nearest = positionMapper.getNearestVisiblePosition(start);
      final rawNearest = positionMapper.visualToRaw(nearest);
      return TextSelection.collapsed(offset: rawNearest);
    }

    return TextSelection(
      baseOffset: adjustedStart,
      extentOffset: adjustedEnd,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  /// Extend a selection in raw coordinates (used when showRawMarkdown is true).
  TextSelection _extendSelectionRaw(
    TextSelection selection,
    bool extendBase,
    int count,
    int maxLength,
  ) {
    if (extendBase) {
      final newBase = (selection.baseOffset + count).clamp(0, maxLength);
      return selection.copyWith(baseOffset: newBase);
    } else {
      final newExtent = (selection.extentOffset + count).clamp(0, maxLength);
      return selection.copyWith(extentOffset: newExtent);
    }
  }

  /// Update the raw markdown mode.
  void setShowRawMarkdown(bool showRaw) {
    showRawMarkdown = showRaw;
  }
}
