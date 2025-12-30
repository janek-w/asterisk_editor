/// Markdown parser that identifies markdown tokens in text.
///
/// Supports basic markdown syntax: headers, bold, italic, code, links,
/// strikethrough, and lists (both ordered and unordered).
///
/// Example:
/// ```dart
/// final parser = MarkdownParser();
/// final tokens = parser.parseText('# Hello **world**');
/// ```
library;

/// Represents a markdown token with its type, position, and content.
class MarkdownToken {
  /// The type of markdown element (e.g., 'header', 'bold', 'italic', 'code', 'link', 'list')
  final String type;
  
  /// Start position of the token in the text
  final int start;
  
  /// End position of the token in the text
  final int end;
  
  /// The actual content of the token (without markdown syntax)
  final String content;
  
  /// Additional metadata (e.g., header level, link URL)
  final Map<String, dynamic> metadata;

  const MarkdownToken({
    required this.type,
    required this.start,
    required this.end,
    required this.content,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'MarkdownToken(type: $type, start: $start, end: $end, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownToken &&
        other.type == type &&
        other.start == start &&
        other.end == end &&
        other.content == content;
  }

  @override
  int get hashCode => type.hashCode ^ start.hashCode ^ end.hashCode ^ content.hashCode;
}

/// Parser for markdown syntax.
///
/// Identifies and extracts markdown tokens from text using regex patterns.
/// Tokens are sorted by start position and non-overlapping.
class MarkdownParser {
  /// Regex patterns for different markdown elements
  static final Map<String, RegExp> _patterns = {
    'header': RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true),
    'bold': RegExp(r'\*\*(.+?)\*\*'),
    'italic': RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
    'code': RegExp(r'`([^`]+)`'),
    'link': RegExp(r'\[(.+?)\]\((.+?)\)'),
    'strikethrough': RegExp(r'~~(.+?)~~'),
    'list_unordered': RegExp(r'^[\-\*]\s+(.+)$', multiLine: true),
    'list_ordered': RegExp(r'^\d+\.\s+(.+)$', multiLine: true),
  };

  /// Parse the entire text and return a list of all markdown tokens.
  ///
  /// This method runs multiple regex passes to identify different markdown
  /// elements, then merges overlapping tokens and sorts by position.
  ///
  /// [text] The markdown text to parse.
  ///
  /// Returns a sorted list of [MarkdownToken] objects representing all
  /// markdown elements found in the text.
  List<MarkdownToken> parseText(String text) {
    final tokens = <MarkdownToken>[];

    // Parse inline styles first (they don't span multiple lines)
    tokens.addAll(_findInlineStyles(text));
    
    // Parse links
    tokens.addAll(_findLinks(text));
    
    // Parse block elements (headers, lists)
    tokens.addAll(_findHeaders(text));
    tokens.addAll(_findLists(text));

    // Merge overlapping tokens and sort by position
    return _mergeAndSortTokens(tokens);
  }

  /// Find all header tokens (H1-H6) in the text.
  ///
  /// Headers are identified by lines starting with 1-6 hash characters (#).
  ///
  /// [text] The text to search for headers.
  ///
  /// Returns a list of header [MarkdownToken] objects.
  List<MarkdownToken> findHeaders(String text) {
    return _findHeaders(text);
  }

  /// Find all bold tokens in the text.
  ///
  /// Bold text is identified by text wrapped in double asterisks (**text**).
  ///
  /// [text] The text to search for bold text.
  ///
  /// Returns a list of bold [MarkdownToken] objects.
  List<MarkdownToken> findBold(String text) {
    return _findByPattern(text, 'bold', _patterns['bold']!);
  }

  /// Find all italic tokens in the text.
  ///
  /// Italic text is identified by text wrapped in single asterisks (*text*).
  ///
  /// [text] The text to search for italic text.
  ///
  /// Returns a list of italic [MarkdownToken] objects.
  List<MarkdownToken> findItalic(String text) {
    return _findByPattern(text, 'italic', _patterns['italic']!);
  }

  /// Find all inline code tokens in the text.
  ///
  /// Inline code is identified by text wrapped in backticks (`text`).
  ///
  /// [text] The text to search for code.
  ///
  /// Returns a list of code [MarkdownToken] objects.
  List<MarkdownToken> findCode(String text) {
    return _findByPattern(text, 'code', _patterns['code']!);
  }

  /// Find all link tokens in the text.
  ///
  /// Links are identified by markdown syntax: [text](url).
  ///
  /// [text] The text to search for links.
  ///
  /// Returns a list of link [MarkdownToken] objects.
  List<MarkdownToken> findLinks(String text) {
    return _findLinks(text);
  }

  /// Find all list tokens (ordered and unordered) in the text.
  ///
  /// Unordered lists start with - or *, ordered lists start with numbers.
  ///
  /// [text] The text to search for lists.
  ///
  /// Returns a list of list [MarkdownToken] objects.
  List<MarkdownToken> findLists(String text) {
    return _findLists(text);
  }

  /// Find all strikethrough tokens in the text.
  ///
  /// Strikethrough text is identified by text wrapped in double tildes (~~text~~).
  ///
  /// [text] The text to search for strikethrough.
  ///
  /// Returns a list of strikethrough [MarkdownToken] objects.
  List<MarkdownToken> findStrikethrough(String text) {
    return _findByPattern(text, 'strikethrough', _patterns['strikethrough']!);
  }

  // Private methods

  /// Find all header tokens (private method).
  List<MarkdownToken> _findHeaders(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['header']!;
    
    for (final match in pattern.allMatches(text)) {
      final hashCount = match.group(1)!.length;
      final content = match.group(2)!;
      
      tokens.add(MarkdownToken(
        type: 'header',
        start: match.start,
        end: match.end,
        content: content,
        metadata: {'level': hashCount},
      ));
    }
    
    return tokens;
  }

  /// Find all inline style tokens (bold, italic, code, strikethrough).
  ///
  /// Processes inline styles in order of specificity to handle nested
  /// styles correctly. Code is most specific, followed by bold, then italic.
  List<MarkdownToken> _findInlineStyles(String text) {
    final tokens = <MarkdownToken>[];
    
    // Find in order of specificity to handle nested styles correctly
    // Code first (most specific), then bold, then italic
    tokens.addAll(_findByPattern(text, 'code', _patterns['code']!));
    tokens.addAll(_findByPattern(text, 'bold', _patterns['bold']!));
    tokens.addAll(_findByPattern(text, 'italic', _patterns['italic']!));
    tokens.addAll(_findByPattern(text, 'strikethrough', _patterns['strikethrough']!));
    
    return tokens;
  }

  /// Find all link tokens (private method).
  List<MarkdownToken> _findLinks(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['link']!;
    
    for (final match in pattern.allMatches(text)) {
      final linkText = match.group(1)!;
      final url = match.group(2)!;
      
      tokens.add(MarkdownToken(
        type: 'link',
        start: match.start,
        end: match.end,
        content: linkText,
        metadata: {'url': url},
      ));
    }
    
    return tokens;
  }

  /// Find all list tokens (both ordered and unordered) (private method).
  List<MarkdownToken> _findLists(String text) {
    final tokens = <MarkdownToken>[];
    
    // Find unordered lists
    tokens.addAll(_findByPattern(text, 'list_unordered', _patterns['list_unordered']!));
    
    // Find ordered lists
    tokens.addAll(_findByPattern(text, 'list_ordered', _patterns['list_ordered']!));
    
    return tokens;
  }

  /// Generic method to find tokens using a regex pattern.
  ///
  /// Iterates through all regex matches and creates tokens for each.
  /// Uses the first capture group if available, otherwise uses the full match.
  ///
  /// [text] The text to search.
  /// [type] The token type identifier.
  /// [pattern] The regex pattern to match.
  ///
  /// Returns a list of [MarkdownToken] objects matching the pattern.
  List<MarkdownToken> _findByPattern(String text, String type, RegExp pattern) {
    final tokens = <MarkdownToken>[];
    
    for (final match in pattern.allMatches(text)) {
      tokens.add(MarkdownToken(
        type: type,
        start: match.start,
        end: match.end,
        content: match.group(1) ?? match.group(0)!,
      ));
    }
    
    return tokens;
  }

  /// Merge overlapping tokens and sort by start position.
  ///
  /// This handles cases where multiple markdown patterns match the same text.
  /// Longer tokens are preferred over shorter ones, and overlapping tokens
  /// are removed to prevent conflicts.
  ///
  /// [tokens] The list of tokens to merge and sort.
  ///
  /// Returns a sorted, non-overlapping list of [MarkdownToken] objects.
  List<MarkdownToken> _mergeAndSortTokens(List<MarkdownToken> tokens) {
    if (tokens.isEmpty) return tokens;
    
    // Sort by start position, then by end position (descending)
    final sortedTokens = List<MarkdownToken>.from(tokens)
      ..sort((a, b) {
        final startCompare = a.start.compareTo(b.start);
        if (startCompare != 0) return startCompare;
        return b.end.compareTo(a.end); // Longer tokens first
      });
    
    // Remove duplicates and handle overlaps
    final mergedTokens = <MarkdownToken>[];
    final usedRanges = <_TextRange>[];
    
    for (final token in sortedTokens) {
      final range = _TextRange(token.start, token.end);
      
      // Check if this token overlaps with any already used range
      bool overlaps = false;
      for (final usedRange in usedRanges) {
        if (range.overlapsWith(usedRange)) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        mergedTokens.add(token);
        usedRanges.add(range);
      }
    }
    
    // Sort by start position for final output
    mergedTokens.sort((a, b) => a.start.compareTo(b.start));
    
    return mergedTokens;
  }
}

/// Helper class to represent a text range.
///
/// Used internally for tracking which text ranges have been
/// assigned to tokens to prevent overlaps.
class _TextRange {
  final int start;
  final int end;
  
  _TextRange(this.start, this.end);

  /// Check if this range overlaps with another range.
  ///
  /// Two ranges overlap if they share any characters.
  bool overlapsWith(_TextRange other) {
    return start < other.end && end > other.start;
  }
  
  @override
  String toString() => '[$start, $end]';
}
