/// TextSpan renderer for markdown tokens.
/// Converts parsed markdown tokens into Flutter TextSpan objects with appropriate styling.
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
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
      fontSize: AppConfig.defaultFontSize,
      height: 1.5,
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
    final syntaxStyle = _createSyntaxStyle(baseTextStyle);

    for (final token in tokens) {
      spans.addAll(_buildUnstyledText(text, lastEnd, token.start, baseTextStyle));
      spans.addAll(_buildTokenWithSyntax(token, baseTextStyle, syntaxStyle));
      lastEnd = token.end;
    }

    spans.addAll(_buildUnstyledText(text, lastEnd, text.length, baseTextStyle));
    return TextSpan(style: baseTextStyle, children: spans);
  }

  /// Build a TextSpan with hidden markdown syntax (Notion/Typora style).
  /// Markdown syntax characters are completely hidden, only formatted content is shown.
  ///
  /// This method uses the token's syntax position information to exclude
  /// syntax characters from the rendered text span.
  TextSpan buildTextSpanWithHiddenSyntax(String text, List<MarkdownToken> tokens, TextStyle baseTextStyle) {
    if (tokens.isEmpty) {
      return TextSpan(text: text, style: baseTextStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final token in tokens) {
      // Add unstyled text before this token (excluding any prefix syntax)
      final visibleStart = token.syntaxPrefixEnd ?? token.start;
      if (visibleStart > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, visibleStart),
          style: baseTextStyle,
        ));
      }

      // Add the styled token content only (no syntax)
      final contentSpan = _createSpanForToken(token);
      spans.add(TextSpan(
        text: contentSpan.text,
        style: baseTextStyle.merge(contentSpan.style),
        children: contentSpan.children,
        recognizer: contentSpan.recognizer,
      ));

      // Move past the token (including any suffix syntax)
      lastEnd = token.syntaxSuffixStart ?? token.end;
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

  /// Create the style for markdown syntax characters.
  ///
  /// Syntax characters are styled subtly with gray color and slightly smaller font
  /// to differentiate them from actual content while maintaining readability.
  TextStyle _createSyntaxStyle(TextStyle baseTextStyle) {
    return baseTextStyle.copyWith(
      color: AppConfig.syntaxTextColor,
      fontSize: (baseTextStyle.fontSize ?? AppConfig.defaultFontSize) * AppConfig.syntaxFontSizeMultiplier,
    );
  }

  /// Build unstyled text spans for the range [start, end).
  ///
  /// Returns an empty list if start >= end.
  List<TextSpan> _buildUnstyledText(
    String text,
    int start,
    int end,
    TextStyle style,
  ) {
    if (start >= end) return [];
    return [TextSpan(text: text.substring(start, end), style: style)];
  }

  /// Build a token with its surrounding syntax characters.
  ///
  /// Creates spans for syntax prefix, the styled token content, and syntax suffix.
  /// Only includes syntax spans if the corresponding characters are present.
  List<TextSpan> _buildTokenWithSyntax(
    MarkdownToken token,
    TextStyle baseStyle,
    TextStyle syntaxStyle,
  ) {
    final syntaxChars = _getSyntaxCharsForToken(token);
    final styledSpan = _createSpanForToken(token);
    final spans = <TextSpan>[];

    if (syntaxChars.prefix.isNotEmpty) {
      spans.add(TextSpan(text: syntaxChars.prefix, style: syntaxStyle));
    }

    spans.add(TextSpan(
      text: styledSpan.text,
      style: baseStyle.merge(styledSpan.style),
      children: styledSpan.children,
      recognizer: styledSpan.recognizer,
    ));

    if (syntaxChars.suffix.isNotEmpty) {
      spans.add(TextSpan(text: syntaxChars.suffix, style: syntaxStyle));
    }

    return spans;
  }

  /// Get the syntax characters (prefix/suffix) for a token.
  ///
  /// Returns the markdown syntax characters that should be displayed
  /// around the token content (e.g., '**' for bold, '#' for headers).
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
  ///
  /// Dispatches to the appropriate style method based on token type.
  /// Returns a basic text span for unknown token types.
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
      case 'task_list':
        return _createTaskListSpan(token);
      case 'fenced_code':
        return _createFencedCodeSpan(token);
      case 'blockquote':
        return _createBlockquoteSpan(token);
      case 'autolink':
        return _createAutolinkSpan(token);
      case 'table':
        return _createTableSpan(token);
      default:
        return TextSpan(text: token.content, style: baseStyle);
    }
  }

  /// Create a styled TextSpan for a header.
  ///
  /// The font size scales based on the header level (1-6),
  /// with H1 being the largest and H6 matching the base font size.
  TextSpan _createHeaderSpan(MarkdownToken token) {
    final level = token.metadata['level'] as int? ?? 1;
    return TextSpan(
      text: token.content,
      style: getHeaderStyle(level),
    );
  }

  /// Create a styled TextSpan for bold text.
  ///
  /// Bold text uses a bold font weight while inheriting other
  /// properties from the base style.
  TextSpan _createBoldSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getBoldStyle(),
    );
  }

  /// Create a styled TextSpan for italic text.
  ///
  /// Italic text uses an italic font style while inheriting other
  /// properties from the base style.
  TextSpan _createItalicSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getItalicStyle(),
    );
  }

  /// Create a styled TextSpan for inline code.
  ///
  /// Code uses a monospace font with a background color
  /// to distinguish it from regular text.
  TextSpan _createCodeSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getCodeStyle(),
    );
  }

  /// Create a styled TextSpan for a link.
  ///
  /// Links use the configured link color and have an underline decoration.
  /// Note: Actual link navigation requires a gesture recognizer at the widget level.
  TextSpan _createLinkSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getLinkStyle(),
      // Note: Actual link navigation would require a gesture recognizer
      // which is handled at the widget level
    );
  }

  /// Create a styled TextSpan for a list item.
  ///
  /// List items use the content directly (without adding bullet prefix).
  /// The bullet/number prefix is rendered separately by the syntax styling
  /// in the visible syntax mode, so we don't add it here.
  /// Both ordered and unordered lists use the same approach.
  TextSpan _createListSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle,
    );
  }

  /// Create a styled TextSpan for strikethrough text.
  ///
  /// Strikethrough text has a line-through decoration
  /// while inheriting other properties from the base style.
  TextSpan _createStrikethroughSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: getStrikethroughStyle(),
    );
  }

  // Style getters

  /// Get the text style for a header of the given level (1-6).
  ///
  /// Font size scales based on header level, with H1 being 2x the base size
  /// and H6 matching the base size. All headers use bold font weight.
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
  ///
  /// Applies bold font weight to the base style.
  TextStyle getBoldStyle() {
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
  }

  /// Get the text style for italic text.
  ///
  /// Applies italic font style to the base style.
  TextStyle getItalicStyle() {
    return baseStyle.copyWith(
      fontStyle: FontStyle.italic,
    );
  }

  /// Get the text style for inline code.
  ///
  /// Uses monospace font with a background color and slightly smaller font size.
  /// Falls back to default background colors if none is specified.
  TextStyle getCodeStyle() {
    return baseStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor: codeBackgroundColor ?? AppConfig.codeBackgroundColorLight,
      fontSize: baseStyle.fontSize! * 0.9,
      height: 1.4,
    );
  }

  /// Get the text style for links.
  ///
  /// Uses the configured link color (or default blue) with underline decoration.
  TextStyle getLinkStyle() {
    return baseStyle.copyWith(
      color: linkColor ?? AppConfig.linkColorLight,
      decoration: TextDecoration.underline,
    );
  }

  /// Get the text style for strikethrough text.
  ///
  /// Applies line-through decoration to the base style.
  TextStyle getStrikethroughStyle() {
    return baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
    );
  }

  /// Get the font size for a header of the given level.
  ///
  /// Uses the centralized configuration for header multipliers.
  /// Falls back to H1 size for invalid levels.
  double _getHeaderFontSize(int level) {
    final baseSize = baseStyle.fontSize ?? AppConfig.defaultFontSize;
    final multiplier = AppConfig.getHeaderMultiplier(level);
    return baseSize * multiplier;
  }

  /// Create a styled TextSpan for a task list item.
  ///
  /// Task list items are rendered with a checkbox indicator and strikethrough
  /// style when checked.
  TextSpan _createTaskListSpan(MarkdownToken token) {
    final isChecked = token.metadata['isChecked'] as bool? ?? false;

    return TextSpan(
      text: token.content,
      style: isChecked
          ? baseStyle.copyWith(
              decoration: TextDecoration.lineThrough,
              color: baseStyle.color?.withOpacity(0.6),
            )
          : baseStyle,
    );
  }

  /// Create a styled TextSpan for a fenced code block.
  ///
  /// Fenced code blocks use monospace font with a background color.
  TextSpan _createFencedCodeSpan(MarkdownToken token) {
    final language = token.metadata['language'] as String?;

    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: codeBackgroundColor ?? AppConfig.getCodeBackgroundColor(false),
        fontSize: baseStyle.fontSize! * 0.9,
        height: 1.4,
      ),
    );
  }

  /// Create a styled TextSpan for a blockquote.
  ///
  /// Blockquotes use italic style and a subtle left border effect
  /// (represented by color change in text).
  TextSpan _createBlockquoteSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: baseStyle.color?.withOpacity(0.8),
      ),
    );
  }

  /// Create a styled TextSpan for an autolink.
  ///
  /// Autolinks are styled like regular links with automatic URL detection.
  TextSpan _createAutolinkSpan(MarkdownToken token) {
    final url = token.metadata['url'] as String? ?? token.content;

    return TextSpan(
      text: token.content,
      style: getLinkStyle(),
      // Note: Actual link navigation would require a gesture recognizer
    );
  }

  /// Create a styled TextSpan for a table row.
  ///
  /// Tables are rendered with tabular spacing (simplified implementation).
  TextSpan _createTableSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle,
    );
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
  ///
  /// Automatically selects appropriate colors based on the current theme
  /// brightness (light or dark mode).
  TextSpanRenderer createThemedRenderer() {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextSpanRenderer(
      baseStyle: theme.textTheme.bodyMedium ??
                 TextStyle(fontSize: AppConfig.defaultFontSize),
      headerColor: theme.textTheme.headlineMedium?.color,
      codeBackgroundColor: AppConfig.getCodeBackgroundColor(isDark),
      linkColor: AppConfig.getLinkColor(isDark),
      listBulletColor: theme.textTheme.bodyMedium?.color,
    );
  }
}
