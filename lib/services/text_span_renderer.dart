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
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, token.start),
            style: baseStyle,
          ),
        );
      }

      // Add the styled token
      spans.add(_createSpanForToken(token));

      lastEnd = token.end;
    }

    // Add remaining unstyled text after the last token
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return spans;
  }

  /// Build a single TextSpan from the given text and markdown tokens.
  /// This is the main entry point for rendering markdown.
  TextSpan buildTextSpan(String text, List<MarkdownToken> tokens) {
    return TextSpan(style: baseStyle, children: buildTextSpans(text, tokens));
  }

  /// Build a TextSpan with visible markdown syntax.
  /// Markdown syntax characters are styled subtly (gray, smaller) to maintain correct cursor positioning.
  TextSpan buildTextSpanWithVisibleSyntax(
    String text,
    List<MarkdownToken> tokens,
    TextStyle baseTextStyle,
  ) {
    if (tokens.isEmpty) {
      return TextSpan(text: text, style: baseTextStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;
    final syntaxStyle = _createSyntaxStyle(baseTextStyle);

    for (final token in tokens) {
      spans.addAll(
        _buildUnstyledText(text, lastEnd, token.start, baseTextStyle),
      );
      spans.addAll(
        _buildStyledTokenSpans(text, token, baseTextStyle, syntaxStyle),
      );
      lastEnd = token.end;
    }

    spans.addAll(_buildUnstyledText(text, lastEnd, text.length, baseTextStyle));
    return TextSpan(style: baseTextStyle, children: spans);
  }

  /// Build text spans for a token using strict source text slicing.
  ///
  /// This ensures that the rendered text has exactly the same length and characters
  /// as the source text, which is critical for correct cursor positioning.
  List<TextSpan> _buildStyledTokenSpans(
    String text,
    MarkdownToken token,
    TextStyle baseStyle,
    TextStyle syntaxStyle,
  ) {
    final spans = <TextSpan>[];

    // 1. Prefix
    if (token.syntaxPrefixStart != null && token.syntaxPrefixEnd != null) {
      final start = token.syntaxPrefixStart!.clamp(0, text.length);
      final end = token.syntaxPrefixEnd!.clamp(0, text.length);

      if (end > start) {
        spans.add(
          TextSpan(text: text.substring(start, end), style: syntaxStyle),
        );
      }
    }

    // 2. Content
    // Determine the content range based on syntax markers or token boundaries
    final contentStart = (token.syntaxPrefixEnd ?? token.start).clamp(
      0,
      text.length,
    );
    final contentEnd = (token.syntaxSuffixStart ?? token.end).clamp(
      0,
      text.length,
    );

    if (contentEnd > contentStart) {
      // Get the style for the content from the token handler
      // We ignore the text returned by _createSpanForToken and ONLY use the style
      final styleSpan = _createSpanForToken(token);
      final mergedStyle = baseStyle.merge(styleSpan.style);

      spans.add(
        TextSpan(
          text: text.substring(contentStart, contentEnd),
          style: mergedStyle,
          // We can include children if needed, but composed spans usually
          // don't work well with this slicing approach unless designed for it.
          // For now, we assume styles are flat for this mode.
          recognizer: styleSpan.recognizer,
        ),
      );
    }

    // 3. Suffix
    if (token.syntaxSuffixStart != null && token.syntaxSuffixEnd != null) {
      final start = token.syntaxSuffixStart!.clamp(0, text.length);
      final end = token.syntaxSuffixEnd!.clamp(0, text.length);

      if (end > start) {
        spans.add(
          TextSpan(text: text.substring(start, end), style: syntaxStyle),
        );
      }
    }

    return spans;
  }

  /// Build a TextSpan with hidden markdown syntax (Notion/Typora style).
  /// Markdown syntax characters are completely hidden, only formatted content is shown.
  ///
  /// This method uses the token's syntax position information to exclude
  /// syntax characters from the rendered text span.
  TextSpan buildTextSpanWithHiddenSyntax(
    String text,
    List<MarkdownToken> tokens,
    TextStyle baseTextStyle,
  ) {
    if (tokens.isEmpty) {
      return TextSpan(text: text, style: baseTextStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final token in tokens) {
      // Add unstyled text before this token (excluding any prefix syntax)
      final visibleStart = token.syntaxPrefixEnd ?? token.start;
      if (visibleStart > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, visibleStart),
            style: baseTextStyle,
          ),
        );
      }

      // Add the styled token content only (no syntax)
      final contentSpan = _createSpanForToken(token);
      spans.add(
        TextSpan(
          text: contentSpan.text,
          style: baseTextStyle.merge(contentSpan.style),
          children: contentSpan.children,
          recognizer: contentSpan.recognizer,
        ),
      );

      // Move past the token (including any suffix syntax)
      lastEnd = token.syntaxSuffixStart ?? token.end;
    }

    // Add remaining unstyled text after the last token
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseTextStyle));
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
      fontSize:
          (baseTextStyle.fontSize ?? AppConfig.defaultFontSize) *
          AppConfig.syntaxFontSizeMultiplier,
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

  /// Create a TextSpan for a specific markdown token.
  ///
  /// Dispatches to the appropriate style method based on token type.
  /// Returns a basic text span for unknown token types.
  TextSpan _createSpanForToken(MarkdownToken token) {
    switch (token.type) {
      // Basic Markdown
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
      // GFM
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
      // Typora Extended - Block Elements
      case 'image':
        return _createImageSpan(token);
      case 'horizontal_rule':
        return _createHorizontalRuleSpan(token);
      case 'math_block':
        return _createMathBlockSpan(token);
      case 'footnote_ref':
        return _createFootnoteRefSpan(token);
      case 'footnote_def':
        return _createFootnoteDefSpan(token);
      case 'yaml_front_matter':
        return _createYamlFrontMatterSpan(token);
      case 'toc':
        return _createTocSpan(token);
      case 'github_alert':
        return _createGithubAlertSpan(token);
      // Typora Extended - Span Elements
      case 'reference_link':
        return _createReferenceLinkSpan(token);
      case 'emoji':
        return _createEmojiSpan(token);
      case 'inline_math':
        return _createInlineMathSpan(token);
      case 'subscript':
        return _createSubscriptSpan(token);
      case 'superscript':
        return _createSuperscriptSpan(token);
      case 'highlight':
        return _createHighlightSpan(token);
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
    return TextSpan(text: token.content, style: getHeaderStyle(level));
  }

  /// Create a styled TextSpan for bold text.
  ///
  /// Bold text uses a bold font weight while inheriting other
  /// properties from the base style.
  TextSpan _createBoldSpan(MarkdownToken token) {
    return TextSpan(text: token.content, style: getBoldStyle());
  }

  /// Create a styled TextSpan for italic text.
  ///
  /// Italic text uses an italic font style while inheriting other
  /// properties from the base style.
  TextSpan _createItalicSpan(MarkdownToken token) {
    return TextSpan(text: token.content, style: getItalicStyle());
  }

  /// Create a styled TextSpan for inline code.
  ///
  /// Code uses a monospace font with a background color
  /// to distinguish it from regular text.
  TextSpan _createCodeSpan(MarkdownToken token) {
    return TextSpan(text: token.content, style: getCodeStyle());
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
    return TextSpan(text: token.content, style: baseStyle);
  }

  /// Create a styled TextSpan for strikethrough text.
  ///
  /// Strikethrough text has a line-through decoration
  /// while inheriting other properties from the base style.
  TextSpan _createStrikethroughSpan(MarkdownToken token) {
    return TextSpan(text: token.content, style: getStrikethroughStyle());
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
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  /// Get the text style for italic text.
  ///
  /// Applies italic font style to the base style.
  TextStyle getItalicStyle() {
    return baseStyle.copyWith(fontStyle: FontStyle.italic);
  }

  /// Get the text style for inline code.
  ///
  /// Uses monospace font with a background color and slightly smaller font size.
  /// Falls back to default background colors if none is specified.
  TextStyle getCodeStyle() {
    return baseStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor:
          codeBackgroundColor ?? AppConfig.codeBackgroundColorLight,
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
    return baseStyle.copyWith(decoration: TextDecoration.lineThrough);
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
        backgroundColor:
            codeBackgroundColor ?? AppConfig.getCodeBackgroundColor(false),
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
    return TextSpan(text: token.content, style: baseStyle);
  }

  // ============================================================
  // Typora Extended Markdown - Block Element Spans
  // ============================================================

  /// Create a styled TextSpan for an image.
  ///
  /// Images show the alt text with a special image style.
  TextSpan _createImageSpan(MarkdownToken token) {
    return TextSpan(
      text: '🖼 ${token.content}',
      style: baseStyle.copyWith(
        color: linkColor ?? AppConfig.linkColorLight,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Create a styled TextSpan for a horizontal rule.
  ///
  /// Horizontal rules are rendered as a line indicator.
  TextSpan _createHorizontalRuleSpan(MarkdownToken token) {
    return TextSpan(
      text: '———',
      style: baseStyle.copyWith(
        color: baseStyle.color?.withOpacity(0.4),
        letterSpacing: 4.0,
      ),
    );
  }

  /// Create a styled TextSpan for a math block.
  ///
  /// Math blocks use monospace font with subtle background.
  TextSpan _createMathBlockSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor:
            codeBackgroundColor ?? AppConfig.codeBackgroundColorLight,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Create a styled TextSpan for a footnote reference.
  ///
  /// Footnote references are styled as superscript links.
  TextSpan _createFootnoteRefSpan(MarkdownToken token) {
    return TextSpan(
      text: '[${token.content}]',
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? AppConfig.defaultFontSize) * 0.75,
        color: linkColor ?? AppConfig.linkColorLight,
      ),
    );
  }

  /// Create a styled TextSpan for a footnote definition.
  ///
  /// Footnote definitions are styled with the footnote id prefix.
  TextSpan _createFootnoteDefSpan(MarkdownToken token) {
    final id = token.metadata['id'] as String? ?? '';
    return TextSpan(
      text: '[$id]: ${token.content}',
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? AppConfig.defaultFontSize) * 0.9,
        color: baseStyle.color?.withOpacity(0.8),
      ),
    );
  }

  /// Create a styled TextSpan for YAML front matter.
  ///
  /// YAML front matter is rendered in monospace with subtle styling.
  TextSpan _createYamlFrontMatterSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: (baseStyle.fontSize ?? AppConfig.defaultFontSize) * 0.85,
        color: baseStyle.color?.withOpacity(0.6),
      ),
    );
  }

  /// Create a styled TextSpan for table of contents marker.
  ///
  /// TOC is rendered as a placeholder indicator.
  TextSpan _createTocSpan(MarkdownToken token) {
    return TextSpan(
      text: '📖 Table of Contents',
      style: baseStyle.copyWith(
        fontWeight: FontWeight.bold,
        color: linkColor ?? AppConfig.linkColorLight,
      ),
    );
  }

  /// Create a styled TextSpan for GitHub-style alerts.
  ///
  /// Alerts have different styling based on alert type (NOTE, TIP, etc).
  TextSpan _createGithubAlertSpan(MarkdownToken token) {
    final alertType = token.metadata['alertType'] as String? ?? 'NOTE';

    Color alertColor;
    String icon;
    switch (alertType.toUpperCase()) {
      case 'NOTE':
        alertColor = const Color(0xFF0969DA);
        icon = 'ℹ️';
        break;
      case 'TIP':
        alertColor = const Color(0xFF1A7F37);
        icon = '💡';
        break;
      case 'IMPORTANT':
        alertColor = const Color(0xFF8250DF);
        icon = '❗';
        break;
      case 'WARNING':
        alertColor = const Color(0xFF9A6700);
        icon = '⚠️';
        break;
      case 'CAUTION':
        alertColor = const Color(0xFFCF222E);
        icon = '🔴';
        break;
      default:
        alertColor = const Color(0xFF0969DA);
        icon = 'ℹ️';
    }

    return TextSpan(
      text: '$icon $alertType: ${token.content}',
      style: baseStyle.copyWith(color: alertColor, fontWeight: FontWeight.w500),
    );
  }

  // ============================================================
  // Typora Extended Markdown - Span Element Spans
  // ============================================================

  /// Create a styled TextSpan for a reference link.
  ///
  /// Reference links are styled like regular links.
  TextSpan _createReferenceLinkSpan(MarkdownToken token) {
    return TextSpan(text: token.content, style: getLinkStyle());
  }

  /// Create a styled TextSpan for emoji.
  ///
  /// Emoji shortcodes are converted to their Unicode equivalent when possible.
  TextSpan _createEmojiSpan(MarkdownToken token) {
    final emojiName = token.content;
    final emoji = _emojiMap[emojiName] ?? ':$emojiName:';

    return TextSpan(text: emoji, style: baseStyle);
  }

  /// Create a styled TextSpan for inline math.
  ///
  /// Inline math uses monospace font with subtle styling.
  TextSpan _createInlineMathSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor:
            codeBackgroundColor ?? AppConfig.codeBackgroundColorLight,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Create a styled TextSpan for subscript text.
  ///
  /// Subscript is rendered smaller and positioned lower.
  TextSpan _createSubscriptSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? AppConfig.defaultFontSize) * 0.7,
        // Note: True subscript positioning requires WidgetSpan or custom paint
        // This is a visual approximation
      ),
    );
  }

  /// Create a styled TextSpan for superscript text.
  ///
  /// Superscript is rendered smaller and positioned higher.
  TextSpan _createSuperscriptSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? AppConfig.defaultFontSize) * 0.7,
        // Note: True superscript positioning requires WidgetSpan or custom paint
        // This is a visual approximation
      ),
    );
  }

  /// Create a styled TextSpan for highlighted text.
  ///
  /// Highlighted text has a yellow background.
  TextSpan _createHighlightSpan(MarkdownToken token) {
    return TextSpan(
      text: token.content,
      style: baseStyle.copyWith(
        backgroundColor: const Color(0xFFFFEB3B), // Yellow highlight
      ),
    );
  }

  /// Common emoji shortcode to Unicode mappings.
  static const Map<String, String> _emojiMap = {
    'smile': '😄',
    'happy': '😊',
    'grinning': '😀',
    'laughing': '😆',
    'wink': '😉',
    'blush': '😊',
    'heart': '❤️',
    'heart_eyes': '😍',
    'star': '⭐',
    'fire': '🔥',
    'thumbsup': '👍',
    'thumbsdown': '👎',
    'ok_hand': '👌',
    'clap': '👏',
    'pray': '🙏',
    'rocket': '🚀',
    'warning': '⚠️',
    'check': '✅',
    'x': '❌',
    'question': '❓',
    'exclamation': '❗',
    'bulb': '💡',
    'memo': '📝',
    'book': '📖',
    'link': '🔗',
    'email': '📧',
    'phone': '📞',
    'calendar': '📅',
    'clock': '🕐',
    'sun': '☀️',
    'moon': '🌙',
    'cloud': '☁️',
    'rain': '🌧️',
    'coffee': '☕',
    'pizza': '🍕',
    'beer': '🍺',
    'tada': '🎉',
    'sparkles': '✨',
    'zap': '⚡',
    'bug': '🐛',
    'wrench': '🔧',
    'hammer': '🔨',
    'gear': '⚙️',
    'lock': '🔒',
    'key': '🔑',
    'dart': '🎯',
    '+1': '👍',
    '-1': '👎',
  };
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
      baseStyle:
          theme.textTheme.bodyMedium ??
          TextStyle(fontSize: AppConfig.defaultFontSize),
      headerColor: theme.textTheme.headlineMedium?.color,
      codeBackgroundColor: AppConfig.getCodeBackgroundColor(isDark),
      linkColor: AppConfig.getLinkColor(isDark),
      listBulletColor: theme.textTheme.bodyMedium?.color,
    );
  }
}
