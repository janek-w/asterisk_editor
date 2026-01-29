/// WYSIWYG (What You See Is What You Get) editing widget for markdown.
/// Renders markdown syntax as styled text in real-time within the same editing pane.
/// Markdown syntax characters are shown but styled subtly to maintain correct cursor positioning.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:asterisk_editor/services/markdown_parser.dart';
import 'package:asterisk_editor/services/text_span_renderer.dart';
import '../../../config/app_config.dart';

/// Custom TextEditingController that builds styled TextSpans from markdown.
class MarkdownTextEditingController extends TextEditingController {
  /// Parser for markdown syntax
  final MarkdownParser parser;
  
  /// Renderer for creating styled TextSpans
  TextSpanRenderer renderer;
  
  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  MarkdownTextEditingController({
    required this.parser,
    required this.renderer,
    String text = '',
    this.onChanged,
  }) : super(text: text);

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    onChanged?.call(newValue.text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    
    // Parse text to get markdown tokens
    final tokens = parser.parseText(text);
    
    // Build the styled TextSpan with visible markdown syntax
    final styledSpan = renderer.buildTextSpanWithVisibleSyntax(text, tokens, style ?? const TextStyle());
    
    return styledSpan;
  }
}

/// WYSIWYG editor widget that renders markdown in real-time.
class WysiwygEditorWidget extends StatefulWidget {
  /// Text controller for the editor content
  final TextEditingController controller;
  
  /// Scroll controller for the editor
  final ScrollController scrollController;
  
  /// Focus node for the editor
  final FocusNode focusNode;
  
  /// Optional callback when text changes
  final ValueChanged<String>? onChanged;
  
  /// Optional callback when text is submitted (e.g., with Enter key)
  final ValueChanged<String>? onSubmitted;

  const WysiwygEditorWidget({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<WysiwygEditorWidget> createState() => _WysiwygEditorWidgetState();
}

class _WysiwygEditorWidgetState extends State<WysiwygEditorWidget> {
  /// Parser for markdown syntax
  final MarkdownParser _parser = MarkdownParser();
  
  /// Custom text controller with markdown rendering
  late MarkdownTextEditingController _markdownController;
  
  /// Timer for debouncing text changes
  Timer? _debounceTimer;
  
  /// Flag to prevent infinite loops
  bool _isUpdatingFromOriginal = false;
  
  /// Last known cursor position from original controller
  int _lastKnownCursorOffset = 0;

  @override
  void initState() {
    super.initState();
    
    // Create custom controller with markdown rendering
    _markdownController = MarkdownTextEditingController(
      parser: _parser,
      renderer: const TextSpanRenderer(), // Will be updated in didChangeDependencies
      text: widget.controller.text,
      onChanged: (text) {
        // Notify parent
        widget.onChanged?.call(text);
      },
    );
    
    // Listen to original controller changes (from Bloc)
    widget.controller.addListener(_onOriginalControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update renderer when theme changes (now it's safe to access context)
    _markdownController.renderer = context.createThemedRenderer();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onOriginalControllerChanged);
    super.dispose();
  }

  /// Handle changes from the original controller (e.g., from Bloc).
  ///
  /// Updates the markdown controller while attempting to preserve cursor position.
  /// When text changes externally, we try to keep the cursor at the
  /// same relative position if possible.
  void _onOriginalControllerChanged() {
    if (_isUpdatingFromOriginal) return;
    
    final originalText = widget.controller.text;
    final markdownText = _markdownController.text;
    
    // Only update if the text actually changed (avoid infinite loop)
    if (originalText != markdownText) {
      // Store current cursor position before update
      _lastKnownCursorOffset = widget.controller.selection.baseOffset;
      
      _isUpdatingFromOriginal = true;
      _markdownController.text = originalText;
      _isUpdatingFromOriginal = false;
      
      // Try to restore cursor position after text update
      // Use WidgetsBinding.instance.addPostFrameCallback to ensure
      // the text field has finished updating before we set the cursor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restoreCursorPosition();
        }
      });
    }
  }
  
  /// Restore cursor position after text update.
  ///
  /// Attempts to place the cursor at the last known position,
  /// clamped to the new text length.
  void _restoreCursorPosition() {
    final textLength = _markdownController.text.length;
    final clampedOffset = _lastKnownCursorOffset.clamp(0, textLength);
    
    _markdownController.selection = TextSelection.collapsed(
      offset: clampedOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar for markdown formatting
          _buildMarkdownToolbar(),
          
          Expanded(
            child: Scrollbar(
              controller: widget.scrollController,
              thumbVisibility: true,
              child: TextField(
                controller: _markdownController,
                focusNode: widget.focusNode,
                scrollController: widget.scrollController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: widget.onSubmitted,
                enableInteractiveSelection: true,
                cursorColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a toolbar with markdown formatting buttons
  Widget _buildMarkdownToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Bold (Ctrl+B)',
              onPressed: () => _insertMarkdown('**', '**'),
            ),
            _buildToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Italic (Ctrl+I)',
              onPressed: () => _insertMarkdown('*', '*'),
            ),
            _buildToolbarButton(
              icon: Icons.code,
              tooltip: 'Inline Code (Ctrl+`)',
              onPressed: () => _insertMarkdown('`', '`'),
            ),
            _buildToolbarButton(
              icon: Icons.title,
              tooltip: 'Header',
              onPressed: () => _insertMarkdown('# ', ''),
            ),
            _buildToolbarButton(
              icon: Icons.link,
              tooltip: 'Link',
              onPressed: () => _insertMarkdown('[', '](url)'),
            ),
            _buildToolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Strikethrough',
              onPressed: () => _insertMarkdown('~~', '~~'),
            ),
            _buildToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
              onPressed: () => _insertMarkdown('- ', ''),
            ),
            _buildToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered List',
              onPressed: () => _insertMarkdown('1. ', ''),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single toolbar button
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        iconSize: AppConfig.toolbarIconSize,
        splashRadius: 20,
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  /// Insert markdown syntax at the current cursor position.
  ///
  /// Inserts the specified [prefix] and [suffix] around the selected text
  /// (or at cursor position if no text is selected). Updates the cursor
  /// position to be after the inserted prefix and selected text.
  void _insertMarkdown(String prefix, String suffix) {
    final controller = _markdownController;
    final selection = controller.selection;
    final text = controller.text;
    
    // Get the selected text
    final selectedText = selection.isValid
        ? text.substring(selection.start, selection.end)
        : '';
    
    // Build the new text with markdown syntax
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );
    
    // Calculate new cursor position
    final newCursorOffset = selection.start + prefix.length + selectedText.length;
    
    // Update the controller with new text and cursor position
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, newText.length),
      ),
    );
    
    // Store the new cursor position for future reference
    _lastKnownCursorOffset = newCursorOffset;
    
    // Force focus back to the editor
    widget.focusNode.requestFocus();
  }
}
