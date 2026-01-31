/// Task list parser for GitHub Flavored Markdown task items.
///
/// Parses task lists (checkboxes) with support for checked/unchecked state.
///
/// Example task lists:
/// ```markdown
/// - [ ] Unchecked task
/// - [x] Checked task
/// * [ ] Another unchecked task
/// ```
library;

import 'markdown_parser.dart';

/// Represents a single task list item with its checkbox state.
class TaskListItem {
  /// The content of the task (without the checkbox markup)
  final String content;

  /// Whether the task is checked (completed)
  final bool isChecked;

  /// The position of the checkbox in the source text
  final int checkboxPosition;

  /// The list marker ('-' or '*')
  final String marker;

  /// The start position of the entire task item in the source text
  final int startPosition;

  /// The end position of the entire task item in the source text
  final int endPosition;

  const TaskListItem({
    required this.content,
    required this.isChecked,
    required this.checkboxPosition,
    required this.marker,
    required this.startPosition,
    required this.endPosition,
  });

  /// Create a copy of this task item with modified fields
  TaskListItem copyWith({
    String? content,
    bool? isChecked,
    int? checkboxPosition,
    String? marker,
    int? startPosition,
    int? endPosition,
  }) {
    return TaskListItem(
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      checkboxPosition: checkboxPosition ?? this.checkboxPosition,
      marker: marker ?? this.marker,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
    );
  }

  /// Get the raw markdown text for this task item
  String get rawText => '$marker [${isChecked ? 'x' : ' '}] $content';

  /// Get the checkbox state as a character ('x' or ' ')
  String get checkboxChar => isChecked ? 'x' : ' ';

  @override
  String toString() =>
      'TaskListItem: "${content.trim()}" (${isChecked ? "checked" : "unchecked"})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskListItem &&
        other.content == content &&
        other.isChecked == isChecked &&
        other.checkboxPosition == checkboxPosition &&
        other.marker == marker &&
        other.startPosition == startPosition &&
        other.endPosition == endPosition;
  }

  @override
  int get hashCode =>
      content.hashCode ^
      isChecked.hashCode ^
      checkboxPosition.hashCode ^
      marker.hashCode ^
      startPosition.hashCode ^
      endPosition.hashCode;
}

/// Parser for task lists in markdown documents.
class TaskListParser {
  /// Regex pattern for matching task list items
  static final RegExp _pattern = RegExp(
    r'^([\-\*])\s+\[([ xX])\]\s+(.+)$',
    multiLine: true,
  );

  /// Parse a single task list item from a line of text.
  ///
  /// [line] The line containing the task item
  /// [position] The start position of the line in the source text
  ///
  /// Returns a [TaskListItem] if the line contains a valid task item,
  /// or null otherwise
  TaskListItem? parseTaskItem(String line, {int position = 0}) {
    final match = _pattern.firstMatch(line);
    if (match == null) return null;

    final marker = match.group(1)!;
    final checkbox = match.group(2)!;
    final content = match.group(3)!;

    // Calculate checkbox position in the source text
    final checkboxOffset = line.indexOf('[');
    final checkboxPosition = position + checkboxOffset;

    return TaskListItem(
      content: content,
      isChecked: checkbox.toLowerCase() == 'x',
      checkboxPosition: checkboxPosition,
      marker: marker,
      startPosition: position,
      endPosition: position + line.length,
    );
  }

  /// Find all task list items in a markdown document.
  ///
  /// [markdown] The full markdown text
  ///
  /// Returns a list of [TaskListItem] objects for all task items found
  List<TaskListItem> findAllTasks(String markdown) {
    final tasks = <TaskListItem>[];
    final lines = markdown.split('\n');

    int currentPosition = 0;
    for (final line in lines) {
      final task = parseTaskItem(line, position: currentPosition);
      if (task != null) {
        tasks.add(task);
      }
      currentPosition += line.length + 1; // +1 for newline
    }

    return tasks;
  }

  /// Create markdown tokens for all task items in the document.
  ///
  /// [markdown] The full markdown text
  ///
  /// Returns a list of [MarkdownToken] objects for all task items
  List<MarkdownToken> createTaskTokens(String markdown) {
    final tasks = findAllTasks(markdown);
    final tokens = <MarkdownToken>[];

    for (final task in tasks) {
      // Calculate syntax positions
      final checkboxStart = task.checkboxPosition;
      final checkboxEnd = checkboxStart + 3; // Length of '[x]' or '[ ]'
      final contentStart = task.startPosition + task.marker.length + 5; // Skip '- [ ] '
      final contentEnd = task.endPosition;

      tokens.add(MarkdownToken(
        type: 'task_list',
        start: task.startPosition,
        end: task.endPosition,
        content: task.content,
        metadata: {
          'isChecked': task.isChecked,
          'checkboxPosition': task.checkboxPosition,
          'marker': task.marker,
        },
        syntaxPrefixStart: task.startPosition,
        syntaxPrefixEnd: contentStart,
        visibility: SyntaxVisibility.hidden,
      ));
    }

    return tokens;
  }

  /// Toggle the checkbox state of a task at the given position.
  ///
  /// [markdown] The full markdown text
  /// [position] The position of the checkbox in the source text
  ///
  /// Returns the updated markdown text with the checkbox toggled,
  /// or null if no checkbox was found at the given position
  String? toggleCheckboxAt(String markdown, int position) {
    // Find the task item containing this position
    final tasks = findAllTasks(markdown);

    for (final task in tasks) {
      // Check if the position is within this task's checkbox
      if (position >= task.checkboxPosition && position < task.checkboxPosition + 3) {
        // Toggle the checkbox
        final toggledTask = task.copyWith(isChecked: !task.isChecked);
        final before = markdown.substring(0, task.startPosition);
        final after = markdown.substring(task.endPosition);
        return before + toggledTask.rawText + after;
      }
    }

    return null;
  }

  /// Check if a position is within a task checkbox.
  ///
  /// [markdown] The full markdown text
  /// [position] The position to check
  ///
  /// Returns true if the position is within a checkbox's brackets
  bool isPositionInCheckbox(String markdown, int position) {
    final tasks = findAllTasks(markdown);

    for (final task in tasks) {
      if (position >= task.checkboxPosition && position < task.checkboxPosition + 3) {
        return true;
      }
    }

    return false;
  }

  /// Get the task item at a given position.
  ///
  /// [markdown] The full markdown text
  /// [position] The position in the source text
  ///
  /// Returns the [TaskListItem] at the position, or null if not found
  TaskListItem? getTaskAt(String markdown, int position) {
    final tasks = findAllTasks(markdown);

    for (final task in tasks) {
      if (position >= task.startPosition && position < task.endPosition) {
        return task;
      }
    }

    return null;
  }

  /// Convert a task list item to plain list item.
  ///
  /// Removes the checkbox and converts to a regular list item.
  ///
  /// [markdown] The full markdown text
  /// [position] The position of the task to convert
  ///
  /// Returns the updated markdown text, or null if no task was found
  String? convertToPlainListItem(String markdown, int position) {
    final task = getTaskAt(markdown, position);
    if (task == null) return null;

    final before = markdown.substring(0, task.startPosition);
    final after = markdown.substring(task.endPosition);
    final plainItem = '${task.marker} ${task.content}';

    return before + plainItem + after;
  }

  /// Convert a plain list item to a task list item.
  ///
  /// [markdown] The full markdown text
  /// [position] The position of the list item to convert
  ///
  /// Returns the updated markdown text, or null if the item is not a valid list item
  String? convertToTaskListItem(String markdown, int position) {
    // This is a simplified implementation - in practice you'd need
    // to properly identify list items that aren't task items
    final lines = markdown.split('\n');

    int currentPosition = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineEnd = currentPosition + line.length;

      if (position >= currentPosition && position < lineEnd) {
        // Check if this is a plain list item
        final listMatch = RegExp(r'^([\-\*])\s+(.+)$').firstMatch(line);
        if (listMatch != null) {
          final marker = listMatch.group(1)!;
          final content = listMatch.group(2)!;
          final before = markdown.substring(0, currentPosition);
          final after = markdown.substring(lineEnd);
          final taskItem = '$marker [ ] $content';

          return before + taskItem + after;
        }
        break;
      }

      currentPosition = lineEnd + 1; // +1 for newline
    }

    return null;
  }
}
