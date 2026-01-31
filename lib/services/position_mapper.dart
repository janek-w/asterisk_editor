/// Position mapper for translating between visual and raw text positions.
///
/// When markdown syntax is hidden from view, the visual cursor position
/// no longer matches the raw text position. This service provides
/// bidirectional mapping between the two coordinate systems.
///
/// Example:
/// - Raw: `**bold**` (8 characters)
/// - Visual: `bold` (4 characters)
/// - Mapping: visual pos 2 → raw pos 4
library;

import 'markdown_parser.dart';

/// Segment of text with visibility information.
///
/// Represents a portion of text with information about whether
/// it contains visible content or hidden syntax characters.
class TextSegment {
  /// The raw text from the original markdown
  final String rawText;

  /// The text that should be visually displayed
  final String visibleText;

  /// Start position in the raw text
  final int rawStart;

  /// End position in the raw text (exclusive)
  final int rawEnd;

  /// Whether this segment contains hidden syntax
  final bool isHidden;

  /// The markdown token associated with this segment (if any)
  final MarkdownToken? token;

  /// Syntax visibility mode for this segment
  final SyntaxVisibility visibility;

  const TextSegment({
    required this.rawText,
    required this.visibleText,
    required this.rawStart,
    required this.rawEnd,
    this.isHidden = false,
    this.token,
    this.visibility = SyntaxVisibility.visible,
  });

  /// Length of the raw text segment
  int get rawLength => rawEnd - rawStart;

  /// Length of the visible text segment
  int get visibleLength => visibleText.length;

  @override
  String toString() {
    return 'TextSegment(raw: "$rawText", visible: "$visibleText", '
        'rawStart: $rawStart, rawEnd: $rawEnd, hidden: $isHidden)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSegment &&
        other.rawText == rawText &&
        other.visibleText == visibleText &&
        other.rawStart == rawStart &&
        other.rawEnd == rawEnd &&
        other.isHidden == isHidden;
  }

  @override
  int get hashCode =>
      rawText.hashCode ^
      visibleText.hashCode ^
      rawStart.hashCode ^
      rawEnd.hashCode ^
      isHidden.hashCode;
}

/// Bidirectional mapper between visual and raw text positions.
///
/// This class maintains a list of text segments and provides
/// methods to translate positions between visual and raw coordinate systems.
/// It's essential for correct cursor positioning when syntax is hidden.
class PositionMapper {
  /// List of text segments representing the entire document
  final List<TextSegment> segments = [];

  /// Cached total visual length
  int _visualLength = 0;

  /// Get the total visual length of all segments
  int get visualLength => _visualLength;

  /// Get the total raw length of all segments
  int get rawLength {
    if (segments.isEmpty) return 0;
    return segments.last.rawEnd;
  }

  /// Rebuild the segment list from raw text and tokens.
  ///
  /// This method should be called whenever the text or tokens change.
  /// It analyzes the text and tokens to create segments with proper
  /// visibility information.
  ///
  /// [rawText] The original markdown text
  /// [tokens] List of parsed markdown tokens
  void rebuild(String rawText, List<MarkdownToken> tokens) {
    segments.clear();
    _visualLength = 0;

    if (rawText.isEmpty) return;

    // Sort tokens by start position
    final sortedTokens = List<MarkdownToken>.from(tokens)
      ..sort((a, b) => a.start.compareTo(b.start));

    int lastEnd = 0;

    for (final token in sortedTokens) {
      // Add unstyled text before this token
      if (token.start > lastEnd) {
        final segmentText = rawText.substring(lastEnd, token.start);
        _addSegment(TextSegment(
          rawText: segmentText,
          visibleText: segmentText,
          rawStart: lastEnd,
          rawEnd: token.start,
          isHidden: false,
          visibility: SyntaxVisibility.visible,
        ));
      }

      // Add the token with its syntax
      _addTokenSegments(rawText, token);

      lastEnd = token.end;
    }

    // Add remaining unstyled text after the last token
    if (lastEnd < rawText.length) {
      final segmentText = rawText.substring(lastEnd);
      _addSegment(TextSegment(
        rawText: segmentText,
        visibleText: segmentText,
        rawStart: lastEnd,
        rawEnd: rawText.length,
        isHidden: false,
        visibility: SyntaxVisibility.visible,
      ));
    }
  }

  /// Add segments for a token and its surrounding syntax.
  ///
  /// Depending on the token type and visibility settings,
  /// this may create multiple segments (prefix, content, suffix).
  void _addTokenSegments(String rawText, MarkdownToken token) {
    final syntaxChars = _getSyntaxCharsForToken(token);
    final tokenContent = token.content;

    // Calculate positions
    final contentStart = token.start + syntaxChars.prefix.length;
    final contentEnd = token.end - syntaxChars.suffix.length;

    // Add prefix segment (if any)
    if (syntaxChars.prefix.isNotEmpty) {
      final prefixRaw = rawText.substring(token.start, contentStart);
      _addSegment(TextSegment(
        rawText: prefixRaw,
        visibleText: '', // Hidden syntax - empty visible text
        rawStart: token.start,
        rawEnd: contentStart,
        isHidden: true,
        token: token,
        visibility: SyntaxVisibility.hidden,
      ));
    }

    // Add content segment
    _addSegment(TextSegment(
      rawText: tokenContent,
      visibleText: tokenContent,
      rawStart: contentStart,
      rawEnd: contentEnd,
      isHidden: false,
      token: token,
      visibility: SyntaxVisibility.visible,
    ));

    // Add suffix segment (if any)
    if (syntaxChars.suffix.isNotEmpty) {
      final suffixRaw = rawText.substring(contentEnd, token.end);
      _addSegment(TextSegment(
        rawText: suffixRaw,
        visibleText: '', // Hidden syntax - empty visible text
        rawStart: contentEnd,
        rawEnd: token.end,
        isHidden: true,
        token: token,
        visibility: SyntaxVisibility.hidden,
      ));
    }
  }

  /// Add a segment to the list and update visual length.
  void _addSegment(TextSegment segment) {
    segments.add(segment);
    _visualLength += segment.visibleLength;
  }

  /// Convert a visual position to a raw position.
  ///
  /// [visualPosition] Position in the visible text
  /// Returns the corresponding position in the raw text
  ///
  /// Throws [RangeError] if visualPosition is out of bounds
  int visualToRaw(int visualPosition) {
    if (visualPosition < 0 || visualPosition > _visualLength) {
      throw RangeError('Visual position $visualPosition is out of bounds (0-$_visualLength)');
    }

    int visualOffset = 0;

    for (final segment in segments) {
      final segmentEnd = visualOffset + segment.visibleLength;

      if (visualPosition <= segmentEnd) {
        // Position is within this segment
        final offsetInSegment = visualPosition - visualOffset;
        return segment.rawStart + offsetInSegment;
      }

      visualOffset = segmentEnd;
    }

    // If we're past all segments, return the end of the raw text
    return rawLength;
  }

  /// Convert a raw position to a visual position.
  ///
  /// [rawPosition] Position in the raw text
  /// Returns the corresponding position in the visible text
  ///
  /// Throws [RangeError] if rawPosition is out of bounds
  int rawToVisual(int rawPosition) {
    if (rawPosition < 0 || rawPosition > rawLength) {
      throw RangeError('Raw position $rawPosition is out of bounds (0-$rawLength)');
    }

    int visualOffset = 0;

    for (final segment in segments) {
      if (rawPosition <= segment.rawEnd) {
        // Position is within or at the end of this segment
        if (rawPosition < segment.rawStart) {
          // Position is before this segment (shouldn't happen with sorted segments)
          return visualOffset;
        }

        final offsetInSegment = rawPosition - segment.rawStart;

        // If this is a hidden segment, the visual position is at segment start
        if (segment.isHidden) {
          return visualOffset;
        }

        return visualOffset + offsetInSegment;
      }

      visualOffset += segment.visibleLength;
    }

    // If we're past all segments, return the end of the visual text
    return _visualLength;
  }

  /// Get the segment at a given raw position.
  ///
  /// [rawPosition] Position in the raw text
  /// Returns the segment containing this position, or null if not found
  TextSegment? getSegmentAtRawPosition(int rawPosition) {
    for (final segment in segments) {
      if (rawPosition >= segment.rawStart && rawPosition < segment.rawEnd) {
        return segment;
      }
    }
    return null;
  }

  /// Get the segment at a given visual position.
  ///
  /// [visualPosition] Position in the visible text
  /// Returns the segment containing this position, or null if not found
  TextSegment? getSegmentAtVisualPosition(int visualPosition) {
    final rawPosition = visualToRaw(visualPosition);
    return getSegmentAtRawPosition(rawPosition);
  }

  /// Clear all segments and reset state.
  void clear() {
    segments.clear();
    _visualLength = 0;
  }

  /// Check if a raw position is within hidden syntax.
  ///
  /// [rawPosition] Position in the raw text
  /// Returns true if the position is within hidden syntax characters
  bool isPositionHidden(int rawPosition) {
    final segment = getSegmentAtRawPosition(rawPosition);
    return segment?.isHidden ?? false;
  }

  /// Get the nearest visible position to a raw position.
  ///
  /// If the raw position is within hidden syntax, this returns
  /// the nearest visible position.
  ///
  /// [rawPosition] Position in the raw text
  /// Returns the nearest position in visible text
  int getNearestVisiblePosition(int rawPosition) {
    final segment = getSegmentAtRawPosition(rawPosition);

    if (segment == null || !segment.isHidden) {
      return rawToVisual(rawPosition);
    }

    // Position is in hidden syntax, find nearest visible position
    // Prefer the end of the previous visible segment
    final segmentIndex = segments.indexOf(segment);

    if (segmentIndex > 0 && segments[segmentIndex - 1].isHidden == false) {
      // Return position after previous visible segment
      int visualOffset = 0;
      for (int i = 0; i < segmentIndex; i++) {
        visualOffset += segments[i].visibleLength;
      }
      return visualOffset;
    }

    // Otherwise, return position at start of next visible segment
    int visualOffset = 0;
    for (final seg in segments) {
      visualOffset += seg.visibleLength;
      if (!seg.isHidden) {
        return visualOffset;
      }
    }

    return _visualLength;
  }
}

/// Helper class for syntax characters extracted from tokens.
class _SyntaxChars {
  final String prefix;
  final String suffix;

  const _SyntaxChars({required this.prefix, required this.suffix});
}

/// Get the syntax characters (prefix/suffix) for a token.
///
/// Returns the markdown syntax characters that surround the token content.
_SyntaxChars _getSyntaxCharsForToken(MarkdownToken token) {
  switch (token.type) {
    case 'header':
      final level = token.metadata['level'] as int? ?? 1;
      return _SyntaxChars(prefix: '#' * level + ' ', suffix: '');
    case 'bold':
      return _SyntaxChars(prefix: '**', suffix: '**');
    case 'italic':
      return _SyntaxChars(prefix: '*', suffix: '*');
    case 'code':
      return _SyntaxChars(prefix: '`', suffix: '`');
    case 'link':
      return _SyntaxChars(prefix: '[', suffix: '](${token.metadata['url'] ?? 'url'})');
    case 'list_unordered':
      return _SyntaxChars(prefix: '- ', suffix: '');
    case 'list_ordered':
      return _SyntaxChars(prefix: '1. ', suffix: '');
    case 'strikethrough':
      return _SyntaxChars(prefix: '~~', suffix: '~~');
    case 'task_list':
      return _SyntaxChars(prefix: '- [', suffix: '] ');
    case 'fenced_code':
      final lang = token.metadata['language'] as String? ?? '';
      return _SyntaxChars(prefix: '```$lang\n', suffix: '\n```');
    case 'blockquote':
      return _SyntaxChars(prefix: '> ', suffix: '');
    case 'table':
      return _SyntaxChars(prefix: '', suffix: '');
    case 'autolink':
      return _SyntaxChars(prefix: '', suffix: '');
    default:
      return _SyntaxChars(prefix: '', suffix: '');
  }
}
