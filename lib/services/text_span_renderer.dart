/// TextSpan renderer for markdown tokens.
/// Converts parsed markdown tokens into Flutter TextSpan objects with appropriate styling.
library;

import 'package:flutter/material.dart';
import 'markdown_parser.dart';

/// Renderer that converts markdown tokens into styled TextSpan objects.
class TextSpanRenderer {
  /// Base text style for normal text
  final TextStyle baseStyle;

  /// Theme colors for different elements
  final Color? headerColor;
  final Color? codeBackgroundColor;
  final Color? linkColor;
  final Color? listBulletColor;

  const TextSpanRenderer({
    this.baseStyle = const TextStyle(
      fontSize: 16,
      height:1.5,
    ),
    this.headerColor,
    this.codeBackgroundColor,
    this.linkColor,
    this.listBulletColor,
  });

  /// Build a list of TextSpans from the given text and markdown tokens.
  /// This method handles both styled and unstyled portions of text.
  List<TextSpan> buildTextSpans(String text, List<MarkdownToken> tokens) {
    if (tokens.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final token in tokens) {
      // Add unstyled text before this token
      if (token.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, token.start),
          style: baseStyle,
        ));
      }

      // Add the styled token
      spans.add(_createSpanForToken(token));

      lastEnd = token.end;
    }

    // Add remaining unstyled text after the last token
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  /// Build a single TextSpan from the given text and markdown tokens.
  /// This is the main entry point for rendering markdown.
  TextSpan buildTextSpan(String text, List<MarkdownToken> tokens) {
    return TextSpan(
      style: baseStyle,
      children: buildTextSpans(text, tokens),
    );
  }

  /// Build a TextSpan with visible markdown syntax.
  /// Markdown syntax characters are styled subtly (gray, smaller) to maintain correct cursor positioning.
  TextSpan buildTextSpanWithVisibleSyntax(String text, List<MarkdownToken> tokens, TextStyle baseTextStyle) {
    if (tokens.isEmpty) {
      return TextSpan(text: text, style: baseTextStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    // Style for markdown syntax characters (subtle gray, slightly smaller)
    final syntaxStyle = baseTextStyle.copyWith(
      color: Colors.grey.shade600,
      fontSize: (baseTextStyle.fontSize ?? 16) * 0.85,
    );

    for (final token in tokens) {
      // Add unstyled text before this token
      if (token.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, token.start),
          style: baseTextStyle,
        ));
      }

      // Determine which syntax characters to show subtly
      final syntaxChars = _getSyntaxCharsForToken(token);
      
      // Add syntax characters with subtle styling
      if (syntaxChars.prefix.isNotEmpty) {
        spans.add(TextSpan(
          text: syntaxChars.prefix,
          style: syntaxStyle,
        ));
      }

      // Add styled token content
      final styledSpan = _createSpanForToken(token);
      spans.add(TextSpan(
        text: styledSpan.text,
        style: baseTextStyle.merge(styledSpan.style),
        children: styledSpan.children,
        recognizer: styledSpan.recognizer,
      ));

      // Add syntax suffix characters with subtle styling
      if (syntaxChars.suffix.isNotEmpty) {
        spans.add(TextSpan(
          text: syntaxChars.suffix,
          style: syntaxStyle,
        ));
      }

      lastEnd = token.end;
    }

    // Add remaining unstyled text after the last token
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseTextStyle,
      ));
    }

    return TextSpan(style: baseTextStyle, children: spans);
  }

  /// Get the syntax characters (prefix/suffix) for a token.
  _SyntaxChars _getSyntaxCharsForToken(MarkdownToken token) {
    switch (token.type) {
      case 'header':
        final level = token.metadata['level'] as int? ??1;
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
      default:
        return _SyntaxChars(prefix: '', suffix: '');
    }
  }

  /// Create a TextSpan for a specific markdown token.
  TextSpan _createSpanForToken(MarkdownToken token) {
    switch (token.type) {
      case 'header':
        return _createHeaderSpan(token);
      case 'bold':
        return _createBoldSpan(token);
      case 'italic':
        return _createItalicSpan(token);
      case 'code':
        return _createCodeSpan(token);
      case 'link':
        return _createLinkSpan(token);
      case 'list_unordered':
      case 'list_ordered':
        return _createListSpan(token);
      case 'strikethrough':
        return _createStrikethroughSpan(token);
      default:
        return TextSpan(text: token.content, style: baseStyle);
    }
  }

  /// Create a styled TextSpan for a header.
  TextSpan _createHeaderSpan(MarkdownToken token) {
    final level = token.metadata['level'] as int? ?? 1;
    return TextSpan(
      text: token.content,
      style: getHeaderStyle(level),
    );
  }

  /// Create a styled TextSpan for bold text.
  TextSpan _createBoldSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getBoldStyle(),
    );
  }

  /// Create a styled TextSpan for italic text.
  TextSpan _createItalicSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getItalicStyle(),
    );
  }

  /// Create a styled TextSpan for inline code.
  TextSpan _createCodeSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getCodeStyle(),
    );
  }

  /// Create a styled TextSpan for a link.
  TextSpan _createLinkSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getLinkStyle(),
      // Note: Actual link navigation would require a gesture recognizer
      // which is handled at the widget level
    );
  }

  /// Create a styled TextSpan for a list item.
  TextSpan _createListSpan(MarkdownToken token) {
    final bullet = token.type == 'list_ordered' ? '• ' : '• ';
    return TextSpan(
      text: '$bullet${token.content}',
      style: baseStyle,
    );
  }

  /// Create a styled TextSpan for strikethrough text.
  TextSpan _createStrikethroughSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getStrikethroughStyle(),
    );
  }

  // Style getters

  /// Get the text style for a header of the given level (1-6).
  TextStyle getHeaderStyle(int level) {
    final fontSize = _getHeaderFontSize(level);
    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: headerColor,
      height: 1.3,
    );
  }

  /// Get the text style for bold text.
  TextStyle getBoldStyle() {
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
  }

  /// Get the text style for italic text.
  TextStyle getItalicStyle() {
    return baseStyle.copyWith(
      fontStyle: FontStyle.italic,
    );
  }

  /// Get the text style for inline code.
  TextStyle getCodeStyle() {
    return baseStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor: codeBackgroundColor ?? const Color(0xFFE0E0E0),
      fontSize: baseStyle.fontSize! * 0.9,
      height: 1.4,
    );
  }

  /// Get the text style for links.
  TextStyle getLinkStyle() {
    return baseStyle.copyWith(
      color: linkColor ?? Colors.blue,
      decoration: TextDecoration.underline,
    );
  }

  /// Get the text style for strikethrough text.
  TextStyle getStrikethroughStyle() {
    return baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
    );
  }

  /// Get the font size for a header of the given level.
  double _getHeaderFontSize(int level) {
    final baseSize = baseStyle.fontSize ?? 16;
    switch (level) {
      case 1:
        return baseSize * 2.0;
      case 2:
        return baseSize * 1.75;
      case 3:
        return baseSize * 1.5;
      case 4:
        return baseSize * 1.25;
      case 5:
        return baseSize * 1.1;
      case 6:
        return baseSize * 1.0;
      default:
        return baseSize * 2.0;
    }
  }
}

/// Helper class for syntax characters.
class _SyntaxChars {
  final String prefix;
  final String suffix;
  
  const _SyntaxChars({required this.prefix, required this.suffix});
}

/// Extension to provide theme-aware renderer instances.
extension TextSpanRendererTheme on BuildContext {
  /// Create a TextSpanRenderer with theme-appropriate colors.
  TextSpanRenderer createThemedRenderer() {
    final theme = Theme.of(this);
    return TextSpanRenderer(
      baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 16),
      headerColor: theme.textTheme.headlineMedium?.color,
      codeBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      linkColor: theme.colorScheme.primary,
      listBulletColor: theme.textTheme.bodyMedium?.color,
    );
  }
}
