/// Interactive checkbox widget for markdown task lists.
///
/// Provides a checkbox that can be toggled by the user and updates
/// the underlying markdown text accordingly.
library;

import 'package:flutter/material.dart';
import '../services/task_list_parser.dart';

/// Callback type for checkbox state changes.
typedef TaskCheckboxCallback = void Function(TaskListItem item, bool isChecked);

/// Interactive checkbox widget for markdown task lists.
///
/// This widget renders a checkbox that matches the task's state
/// and calls the provided callback when toggled.
class MarkdownCheckbox extends StatefulWidget {
  /// The task item this checkbox represents
  final TaskListItem item;

  /// Callback when the checkbox is toggled
  final TaskCheckboxCallback? onToggle;

  /// Size of the checkbox
  final double size;

  /// Color when checked
  final Color? checkedColor;

  /// Color when unchecked
  final Color? uncheckedColor;

  /// Border radius of the checkbox
  final double borderRadius;

  const MarkdownCheckbox({
    super.key,
    required this.item,
    this.onToggle,
    this.size = 20.0,
    this.checkedColor,
    this.uncheckedColor,
    this.borderRadius = 4.0,
  });

  @override
  State<MarkdownCheckbox> createState() => _MarkdownCheckboxState();
}

class _MarkdownCheckboxState extends State<MarkdownCheckbox> {
  bool _isChecked = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.item.isChecked;
  }

  @override
  void didUpdateWidget(MarkdownCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isChecked != widget.item.isChecked) {
      _isChecked = widget.item.isChecked;
    }
  }

  void _handleTap() {
    setState(() {
      _isChecked = !_isChecked;
    });
    widget.onToggle?.call(widget.item, _isChecked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedColor = widget.checkedColor ?? theme.colorScheme.primary;
    final uncheckedColor = widget.uncheckedColor ?? theme.dividerColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isChecked ? checkedColor : uncheckedColor,
              width: _isHovered ? 2.0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: _isChecked ? checkedColor.withOpacity(0.2) : Colors.transparent,
          ),
          child: _isChecked
              ? Padding(
                  padding: EdgeInsets.all(widget.size * 0.15),
                  child: CustomPaint(
                    size: Size.square(widget.size * 0.7),
                    painter: _CheckmarkPainter(color: checkedColor),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Custom painter for drawing a checkmark.
class _CheckmarkPainter extends CustomPainter {
  final Color color;

  _CheckmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Draw checkmark
    final startPoint = Offset(size.width * 0.2, size.height * 0.5);
    final middlePoint = Offset(size.width * 0.4, size.height * 0.7);
    final endPoint = Offset(size.width * 0.8, size.height * 0.3);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(middlePoint.dx, middlePoint.dy);
    path.lineTo(endPoint.dx, endPoint.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget span for embedding checkboxes in text.
///
/// This widget can be used with WidgetSpan to embed checkboxes
/// directly in the text flow.
class MarkdownCheckboxWidgetSpan extends WidgetSpan {
  MarkdownCheckboxWidgetSpan({
    required TaskListItem item,
    required TaskCheckboxCallback? onToggle,
    double size = 20.0,
    Color? checkedColor,
    Color? uncheckedColor,
    PlaceholderAlignment alignment = PlaceholderAlignment.middle,
  }) : super(
          child: MarkdownCheckbox(
            item: item,
            onToggle: onToggle,
            size: size,
            checkedColor: checkedColor,
            uncheckedColor: uncheckedColor,
          ),
          alignment: alignment,
        );
}

/// Builder function for creating checkbox widgets in text spans.
///
/// This function can be used by the text renderer to insert
/// checkboxes for task list items.
typedef CheckboxBuilder = Widget Function(TaskListItem item, TaskCheckboxCallback? onToggle);

/// Default checkbox builder that creates a standard MarkdownCheckbox.
Widget defaultCheckboxBuilder(TaskListItem item, TaskCheckboxCallback? onToggle) {
  return MarkdownCheckbox(
    item: item,
    onToggle: onToggle,
    size: 18.0,
  );
}

/// Checkbox widget with inline text support.
///
/// This variant is designed to be used inline with text,
/// similar to how bullet points work in lists.
class InlineMarkdownCheckbox extends StatelessWidget {
  /// The task item this checkbox represents
  final TaskListItem item;

  /// Callback when the checkbox is toggled
  final TaskCheckboxCallback? onToggle;

  /// Size of the checkbox
  final double size;

  /// Spacing after the checkbox
  final double spacing;

  const InlineMarkdownCheckbox({
    super.key,
    required this.item,
    this.onToggle,
    this.size = 18.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarkdownCheckbox(
          item: item,
          onToggle: onToggle,
          size: size,
        ),
        SizedBox(width: spacing),
      ],
    );
  }
}
