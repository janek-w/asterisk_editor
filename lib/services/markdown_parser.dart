/// Markdown parser that identifies markdown tokens in text.
///
/// Supports basic markdown syntax: headers, bold, italic, code, links,
/// strikethrough, and lists (both ordered and unordered).
///
/// Also supports GitHub Flavored Markdown (GFM): task lists, fenced code blocks,
/// blockquotes, autolinks, and tables.
///
/// Example:
/// ```dart
/// final parser = MarkdownParser();
/// final tokens = parser.parseText('# Hello **world**');
/// ```
library;

/// Visibility mode for markdown syntax characters.
enum SyntaxVisibility {
  /// Syntax is fully visible
  visible,

  /// Syntax is hidden (Notion/Typora style)
  hidden,

  /// Syntax is replaced with a placeholder
  placeholder,
}

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

  /// Start position of the syntax prefix (e.g., '**' in '**bold**')
  final int? syntaxPrefixStart;

  /// End position of the syntax prefix (exclusive)
  final int? syntaxPrefixEnd;

  /// Start position of the syntax suffix (e.g., '**' in '**bold**')
  final int? syntaxSuffixStart;

  /// End position of the syntax suffix (exclusive)
  final int? syntaxSuffixEnd;

  /// Visibility mode for this token's syntax
  final SyntaxVisibility visibility;

  const MarkdownToken({
    required this.type,
    required this.start,
    required this.end,
    required this.content,
    this.metadata = const {},
    this.syntaxPrefixStart,
    this.syntaxPrefixEnd,
    this.syntaxSuffixStart,
    this.syntaxSuffixEnd,
    this.visibility = SyntaxVisibility.visible,
  });

  /// Get the length of the syntax prefix
  int get syntaxPrefixLength => (syntaxPrefixEnd ?? start) - (syntaxPrefixStart ?? start);

  /// Get the length of the syntax suffix
  int get syntaxSuffixLength => (syntaxSuffixEnd ?? end) - (syntaxSuffixStart ?? end);

  /// Check if this token has visible syntax
  bool get hasVisibleSyntax => visibility != SyntaxVisibility.hidden;

  /// Create a copy of this token with modified fields
  MarkdownToken copyWith({
    String? type,
    int? start,
    int? end,
    String? content,
    Map<String, dynamic>? metadata,
    int? syntaxPrefixStart,
    int? syntaxPrefixEnd,
    int? syntaxSuffixStart,
    int? syntaxSuffixEnd,
    SyntaxVisibility? visibility,
  }) {
    return MarkdownToken(
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      syntaxPrefixStart: syntaxPrefixStart ?? this.syntaxPrefixStart,
      syntaxPrefixEnd: syntaxPrefixEnd ?? this.syntaxPrefixEnd,
      syntaxSuffixStart: syntaxSuffixStart ?? this.syntaxSuffixStart,
      syntaxSuffixEnd: syntaxSuffixEnd ?? this.syntaxSuffixEnd,
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  String toString() {
    return 'MarkdownToken(type: $type, start: $start, end: $end, content: $content, visibility: $visibility)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownToken &&
        other.type == type &&
        other.start == start &&
        other.end == end &&
        other.content == content &&
        other.visibility == visibility;
  }

  @override
  int get hashCode => type.hashCode ^ start.hashCode ^ end.hashCode ^ content.hashCode ^ visibility.hashCode;
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
    // GFM patterns
    'task_list': RegExp(r'^[\-\*]\s+\[([ x])\]\s+(.+)$', multiLine: true, caseSensitive: false),
    'fenced_code': RegExp(r'^```(\w*)\n([\s\S]+?)\n```$', multiLine: true),
    'blockquote': RegExp(r'^>\s+(.+)$', multiLine: true),
    'autolink': RegExp(r'(https?://[^\s]+)'),
    // Table pattern (simplified - full table parsing is complex)
    'table': RegExp(r'^\|?([^|\n]+)\|.+$', multiLine: true),
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

    // Parse GFM elements
    tokens.addAll(_findTaskLists(text));
    tokens.addAll(_findFencedCode(text));
    tokens.addAll(_findBlockquotes(text));
    tokens.addAll(_findAutolinks(text));
    tokens.addAll(_findTables(text));

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

  /// Find all task list tokens in the text.
  ///
  /// Task lists are identified by `- [ ]` or `- [x]` syntax.
  ///
  /// [text] The text to search for task lists.
  ///
  /// Returns a list of task list [MarkdownToken] objects.
  List<MarkdownToken> findTaskLists(String text) {
    return _findTaskLists(text);
  }

  /// Find all fenced code block tokens in the text.
  ///
  /// Fenced code blocks are identified by triple backticks.
  ///
  /// [text] The text to search for fenced code blocks.
  ///
  /// Returns a list of fenced code [MarkdownToken] objects.
  List<MarkdownToken> findFencedCode(String text) {
    return _findFencedCode(text);
  }

  /// Find all blockquote tokens in the text.
  ///
  /// Blockquotes are identified by lines starting with `>`.
  ///
  /// [text] The text to search for blockquotes.
  ///
  /// Returns a list of blockquote [MarkdownToken] objects.
  List<MarkdownToken> findBlockquotes(String text) {
    return _findBlockquotes(text);
  }

  /// Find all autolink tokens in the text.
  ///
  /// Autolinks are automatically detected URLs.
  ///
  /// [text] The text to search for autolinks.
  ///
  /// Returns a list of autolink [MarkdownToken] objects.
  List<MarkdownToken> findAutolinks(String text) {
    return _findAutolinks(text);
  }

  /// Find all table tokens in the text.
  ///
  /// Tables are identified by pipe-separated rows.
  ///
  /// [text] The text to search for tables.
  ///
  /// Returns a list of table [MarkdownToken] objects.
  List<MarkdownToken> findTables(String text) {
    return _findTables(text);
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

  /// Find all task list tokens in the text.
  ///
  /// Task lists are identified by `- [ ]` or `- [x]` syntax.
  ///
  /// [text] The text to search for task lists.
  ///
  /// Returns a list of task list [MarkdownToken] objects.
  List<MarkdownToken> _findTaskLists(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['task_list']!;

    for (final match in pattern.allMatches(text)) {
      final checkboxState = match.group(1)!;
      final content = match.group(2)!;
      final isChecked = checkboxState.toLowerCase() == 'x';

      // Calculate syntax positions
      final checkboxStart = match.start + match.group(0)!.indexOf('[');
      final checkboxEnd = checkboxStart + 3; // Length of '[x]' or '[ ]'

      tokens.add(MarkdownToken(
        type: 'task_list',
        start: match.start,
        end: match.end,
        content: content,
        metadata: {
          'isChecked': isChecked,
          'checkboxPosition': checkboxStart,
        },
        syntaxPrefixStart: match.start,
        syntaxPrefixEnd: checkboxEnd,
        visibility: SyntaxVisibility.hidden,
      ));
    }

    return tokens;
  }

  /// Find all fenced code block tokens in the text.
  ///
  /// Fenced code blocks are identified by triple backticks with optional language.
  ///
  /// [text] The text to search for fenced code blocks.
  ///
  /// Returns a list of fenced code [MarkdownToken] objects.
  List<MarkdownToken> _findFencedCode(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['fenced_code']!;

    for (final match in pattern.allMatches(text)) {
      final language = match.group(1)!;
      final code = match.group(2)!;

      // Calculate syntax positions
      final firstNewline = match.group(0)!.indexOf('\n');
      final lastNewline = match.group(0)!.lastIndexOf('\n');

      tokens.add(MarkdownToken(
        type: 'fenced_code',
        start: match.start,
        end: match.end,
        content: code,
        metadata: {
          'language': language,
        },
        syntaxPrefixStart: match.start,
        syntaxPrefixEnd: match.start + firstNewline,
        syntaxSuffixStart: match.start + lastNewline,
        syntaxSuffixEnd: match.end,
        visibility: SyntaxVisibility.hidden,
      ));
    }

    return tokens;
  }

  /// Find all blockquote tokens in the text.
  ///
  /// Blockquotes are identified by lines starting with `>`.
  ///
  /// [text] The text to search for blockquotes.
  ///
  /// Returns a list of blockquote [MarkdownToken] objects.
  List<MarkdownToken> _findBlockquotes(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['blockquote']!;

    for (final match in pattern.allMatches(text)) {
      final content = match.group(1)!;

      tokens.add(MarkdownToken(
        type: 'blockquote',
        start: match.start,
        end: match.end,
        content: content,
        syntaxPrefixStart: match.start,
        syntaxPrefixEnd: match.start + 2, // Length of '> '
        visibility: SyntaxVisibility.hidden,
      ));
    }

    return tokens;
  }

  /// Find all autolink tokens in the text.
  ///
  /// Autolinks are automatically detected URLs.
  ///
  /// [text] The text to search for autolinks.
  ///
  /// Returns a list of autolink [MarkdownToken] objects.
  List<MarkdownToken> _findAutolinks(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['autolink']!;

    for (final match in pattern.allMatches(text)) {
      final url = match.group(0)!;

      tokens.add(MarkdownToken(
        type: 'autolink',
        start: match.start,
        end: match.end,
        content: url,
        metadata: {
          'url': url,
        },
      ));
    }

    return tokens;
  }

  /// Find all table tokens in the text.
  ///
  /// Tables are identified by pipe-separated rows.
  /// This is a simplified implementation - full table parsing requires
  /// analyzing multiple rows and alignment.
  ///
  /// [text] The text to search for tables.
  ///
  /// Returns a list of table [MarkdownToken] objects.
  List<MarkdownToken> _findTables(String text) {
    final tokens = <MarkdownToken>[];
    final pattern = _patterns['table']!;

    for (final match in pattern.allMatches(text)) {
      final rowContent = match.group(1)!;

      tokens.add(MarkdownToken(
        type: 'table',
        start: match.start,
        end: match.end,
        content: rowContent,
        metadata: {
          'isHeader': false, // Will be determined by table parser
        },
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
