/// WYSIWYG (What You See Is What You Get) editing widget for markdown.
///
/// Supports two rendering modes:
/// 1. Visible syntax: Markdown syntax is shown but styled subtly
/// 2. Hidden syntax: Markdown syntax is hidden (Notion/Typora style)
///
/// The rendering mode is controlled by AppConfig.enableHiddenSyntax feature flag
/// and can be toggled at runtime via the BLoC.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asterisk_editor/services/markdown_parser.dart';
import 'package:asterisk_editor/services/text_span_renderer.dart';
import 'package:asterisk_editor/services/position_mapper.dart';
import 'package:asterisk_editor/services/cursor_manager.dart';
import 'package:asterisk_editor/services/selection_mapper.dart';
import '../../../config/app_config.dart';

/// Custom TextEditingController that builds styled TextSpans from markdown.
///
/// This controller supports both visible and hidden syntax rendering modes
/// depending on AppConfig.enableHiddenSyntax.
class MarkdownTextEditingController extends TextEditingController {
  /// Parser for markdown syntax
  final MarkdownParser parser;

  /// Renderer for creating styled TextSpans
  TextSpanRenderer renderer;

  /// Position mapper for translating between visual and raw positions
  final PositionMapper positionMapper;

  /// Cursor manager for handling cursor position with hidden syntax
  final CursorManager cursorManager;

  /// Selection mapper for handling text selection with hidden syntax
  final SelectionMapper selectionMapper;

  /// Whether to show raw markdown (syntax visible) or hide syntax
  bool showRawMarkdown;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  MarkdownTextEditingController({
    required this.parser,
    required this.renderer,
    required this.positionMapper,
    required this.cursorManager,
    required this.selectionMapper,
    String text = '',
    this.showRawMarkdown = false,
    this.onChanged,
  }) : super(text: text) {
    // Initial parse
    _updatePositionMapping();
  }

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    _updatePositionMapping();
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

    // Update position mapping
    if (!showRawMarkdown) {
      positionMapper.rebuild(text, tokens);
    }

    // Build the appropriate TextSpan based on mode
    final baseTextStyle = style ?? const TextStyle();
    if (showRawMarkdown || !AppConfig.enableHiddenSyntax) {
      return renderer.buildTextSpanWithVisibleSyntax(
        text,
        tokens,
        baseTextStyle,
      );
    } else {
      return renderer.buildTextSpanWithHiddenSyntax(
        text,
        tokens,
        baseTextStyle,
      );
    }
  }

  /// Toggle between raw markdown and hidden syntax mode.
  void toggleSyntaxVisibility() {
    showRawMarkdown = !showRawMarkdown;
    cursorManager.setShowRawMarkdown(showRawMarkdown);
    selectionMapper.setShowRawMarkdown(showRawMarkdown);
    _updatePositionMapping();
    notifyListeners();
  }

  /// Set the syntax visibility mode.
  void setSyntaxVisibility(bool showRaw) {
    if (showRawMarkdown != showRaw) {
      showRawMarkdown = showRaw;
      cursorManager.setShowRawMarkdown(showRaw);
      selectionMapper.setShowRawMarkdown(showRaw);
      _updatePositionMapping();
      notifyListeners();
    }
  }

  /// Update the position mapping based on current text.
  void _updatePositionMapping() {
    if (!showRawMarkdown) {
      final tokens = parser.parseText(text);
      positionMapper.rebuild(text, tokens);
    } else {
      positionMapper.clear();
    }
  }

  /// Handle a tap event at a visual position.
  CursorPositionResult handleTap(int visualPosition) {
    return cursorManager.handleTapAtVisualPosition(visualPosition, text);
  }

  /// Check if a position is in hidden syntax.
  bool isPositionHidden(int rawPosition) {
    return cursorManager.isPositionHidden(rawPosition);
  }

  /// Get the nearest visible position.
  int getNearestVisiblePosition(int rawPosition) {
    return cursorManager.getNearestVisiblePosition(rawPosition);
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

  /// Whether to show raw markdown (from BLoC state)
  final bool showRawMarkdown;

  const WysiwygEditorWidget({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.showRawMarkdown = false,
  });

  @override
  State<WysiwygEditorWidget> createState() => _WysiwygEditorWidgetState();
}

class _WysiwygEditorWidgetState extends State<WysiwygEditorWidget> {
  /// Parser for markdown syntax
  final MarkdownParser _parser = MarkdownParser();

  /// Position mapper for translating between visual and raw positions
  final PositionMapper _positionMapper = PositionMapper();

  /// Cursor manager for handling cursor position
  late CursorManager _cursorManager;

  /// Selection mapper for handling text selection
  late SelectionMapper _selectionMapper;

  /// Custom text controller with markdown rendering
  late MarkdownTextEditingController _markdownController;

  /// Timer for debouncing text changes
  Timer? _debounceTimer;

  /// Flag to prevent infinite loops
  bool _isUpdatingFromOriginal = false;

  /// Last known cursor position from original controller
  int _lastKnownCursorOffset = 0;

  /// GlobalKey for accessing the TextField state
  final GlobalKey _textFieldKey = GlobalKey();

  /// The text position from the last tap event
  TextPosition? _lastTapPosition;

  @override
  void initState() {
    super.initState();

    // Initialize cursor and selection managers
    _cursorManager = CursorManager(
      positionMapper: _positionMapper,
      showRawMarkdown: widget.showRawMarkdown,
    );
    _selectionMapper = SelectionMapper(
      positionMapper: _positionMapper,
      showRawMarkdown: widget.showRawMarkdown,
    );

    // Create custom controller with markdown rendering
    _markdownController = MarkdownTextEditingController(
      parser: _parser,
      renderer:
          const TextSpanRenderer(), // Will be updated in didChangeDependencies
      positionMapper: _positionMapper,
      cursorManager: _cursorManager,
      selectionMapper: _selectionMapper,
      text: widget.controller.text,
      showRawMarkdown: widget.showRawMarkdown,
      onChanged: (text) {
        // Sync changes back to the original controller to ensure
        // edits are preserved when switching between editor modes
        if (!_isUpdatingFromOriginal && widget.controller.text != text) {
          _isUpdatingFromOriginal = true;
          widget.controller.text = text;
          _isUpdatingFromOriginal = false;
        }
        // Notify parent
        widget.onChanged?.call(text);
      },
    );

    // Listen to original controller changes (from Bloc)
    widget.controller.addListener(_onOriginalControllerChanged);
  }

  @override
  void didUpdateWidget(WysiwygEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showRawMarkdown != widget.showRawMarkdown) {
      _markdownController.setSyntaxVisibility(widget.showRawMarkdown);
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restoreCursorPosition();
        }
      });
    }
  }

  /// Restore cursor position after text update.
  void _restoreCursorPosition() {
    final textLength = _markdownController.text.length;
    final clampedOffset = _lastKnownCursorOffset.clamp(0, textLength);

    _markdownController.selection = TextSelection.collapsed(
      offset: clampedOffset,
    );
  }

  /// Handle tap events on the text field.
  ///
  /// When hidden syntax is enabled, we need to translate tap positions
  /// from visual to raw coordinates.
  void _handleTapDown(TapDownDetails details) {
    if (!AppConfig.enableHiddenSyntax || widget.showRawMarkdown) {
      return;
    }

    // Get the text position from the tap
    final textPosition = _getTextPositionFromGlobalPosition(
      details.globalPosition,
    );
    if (textPosition != null) {
      setState(() {
        _lastTapPosition = textPosition;
      });

      // Handle the tap with cursor manager
      final result = _markdownController.handleTap(textPosition.offset);

      // Update the selection if the cursor was adjusted
      if (result.wasAdjusted) {
        _markdownController.selection = TextSelection.collapsed(
          offset: result.rawPosition,
        );
      }
    }
  }

  /// Get the text position from a global position.
  TextPosition? _getTextPositionFromGlobalPosition(Offset globalPosition) {
    final RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return null;

    // Convert global position to local position
    final localPosition = textFieldBox.globalToLocal(globalPosition);

    // Get the text position from the local position
    // This is a simplified implementation - in production you'd use
    // the TextPainter to get the exact position
    final TextPainter? textPainter = _getTextPainter();
    if (textPainter == null) return null;

    // For now, return a simple approximation
    // In production, you'd use textPainter.getPositionForOffset(localPosition)
    return null;
  }

  /// Get the TextPainter for the current text.
  TextPainter? _getTextPainter() {
    // This would return the TextPainter used by the TextField
    // For now, return null as this requires access to internal TextField state
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final useHiddenSyntax =
        AppConfig.enableHiddenSyntax && !widget.showRawMarkdown;

    return Padding(
      padding: const EdgeInsets.only(
        top: 4.0,
        left: 4.0,
        right: 4.0,
        bottom: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar for markdown formatting
          _buildMarkdownToolbar(),

          Expanded(
            child: GestureDetector(
              onTapDown: useHiddenSyntax ? _handleTapDown : null,
              child: Scrollbar(
                controller: widget.scrollController,
                thumbVisibility: true,
                child: TextField(
                  key: _textFieldKey,
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
                  enableInteractiveSelection: !useHiddenSyntax,
                  cursorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a toolbar with markdown formatting buttons.
  Widget _buildMarkdownToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
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
            if (AppConfig.enableHiddenSyntax)
              _buildToolbarButton(
                icon: Icons.code_off,
                tooltip: widget.showRawMarkdown ? 'Hide Syntax' : 'Show Raw',
                onPressed: () {
                  // This would dispatch a ToggleSyntaxVisibility event to the BLoC
                  // For now, just toggle locally
                  _markdownController.toggleSyntaxVisibility();
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Build a single toolbar button.
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
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  /// Insert markdown syntax at the current cursor position.
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
    final newCursorOffset =
        selection.start + prefix.length + selectedText.length;

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
