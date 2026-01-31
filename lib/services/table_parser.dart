/// Table parser for GitHub Flavored Markdown tables.
///
/// Parses markdown tables with support for column alignment
/// (left, center, right) and proper cell extraction.
///
/// Example table:
/// ```markdown
/// | Header 1 | Header 2 | Header 3 |
/// |----------|:--------:|---------:|
/// | Cell 1   | Cell 2   | Cell 3   |
/// ```
library;

import 'markdown_parser.dart';

/// Column alignment options for table columns.
enum ColumnAlignment {
  /// Text aligned to the left (default)
  left,

  /// Text centered in the column
  center,

  /// Text aligned to the right
  right,

  /// No specific alignment
  none,
}

/// Represents a single cell in a table.
class TableCell {
  /// The content of the cell (without leading/trailing pipes and spaces)
  final String content;

  /// The column index (0-based)
  final int columnIndex;

  /// Whether this cell is a header cell
  final bool isHeader;

  const TableCell({
    required this.content,
    required this.columnIndex,
    this.isHeader = false,
  });

  @override
  String toString() => 'TableCell[$columnIndex]: "$content"${isHeader ? " (header)" : ""}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableCell &&
        other.content == content &&
        other.columnIndex == columnIndex &&
        other.isHeader == isHeader;
  }

  @override
  int get hashCode => content.hashCode ^ columnIndex.hashCode ^ isHeader.hashCode;
}

/// Represents a single row in a table.
class TableRow {
  /// The cells in this row
  final List<TableCell> cells;

  /// The row index (0-based)
  final int rowIndex;

  /// Whether this is the header row
  final bool isHeader;

  const TableRow({
    required this.cells,
    required this.rowIndex,
    this.isHeader = false,
  });

  /// Get the number of cells in this row
  int get cellCount => cells.length;

  /// Get a cell by column index
  TableCell? getCell(int columnIndex) {
    if (columnIndex >= 0 && columnIndex < cells.length) {
      return cells[columnIndex];
    }
    return null;
  }

  @override
  String toString() => 'TableRow[$rowIndex]${isHeader ? " (header)" : ""}: ${cells.length} cells';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableRow &&
        other.cells.length == cells.length &&
        other.rowIndex == rowIndex &&
        other.isHeader == isHeader;
  }

  @override
  int get hashCode => cells.length.hashCode ^ rowIndex.hashCode ^ isHeader.hashCode;
}

/// Represents the complete structure of a markdown table.
class TableStructure {
  /// The header row (may be null if no header row is present)
  final TableRow? headerRow;

  /// The data rows (excluding the separator row)
  final List<TableRow> dataRows;

  /// The alignment for each column
  final List<ColumnAlignment> columnAlignments;

  /// The position in the source text where this table starts
  final int startPosition;

  /// The position in the source text where this table ends
  final int endPosition;

  const TableStructure({
    this.headerRow,
    required this.dataRows,
    required this.columnAlignments,
    required this.startPosition,
    required this.endPosition,
  });

  /// Get the total number of rows (including header if present)
  int get rowCount => dataRows.length + (headerRow != null ? 1 : 0);

  /// Get the number of columns
  int get columnCount => columnAlignments.length;

  /// Get the alignment for a specific column
  ColumnAlignment getAlignment(int columnIndex) {
    if (columnIndex >= 0 && columnIndex < columnAlignments.length) {
      return columnAlignments[columnIndex];
    }
    return ColumnAlignment.none;
  }

  /// Check if this table has a header row
  bool get hasHeader => headerRow != null;

  /// Get all rows including the header (if present)
  List<TableRow> get allRows {
    if (headerRow != null) {
      return [headerRow!, ...dataRows];
    }
    return dataRows;
  }

  @override
  String toString() =>
      'TableStructure: $columnCount columns, $rowCount rows${hasHeader ? " (with header)" : ""}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableStructure &&
        other.rowCount == rowCount &&
        other.columnCount == columnCount &&
        other.startPosition == startPosition &&
        other.endPosition == endPosition;
  }

  @override
  int get hashCode => rowCount.hashCode ^ columnCount.hashCode ^ startPosition.hashCode ^ endPosition.hashCode;
}

/// Parser for markdown tables with alignment support.
class TableParser {
  /// Regex pattern for matching table rows
  static final RegExp _rowPattern = RegExp(r'^\|?(.+)\|?\s*$');

  /// Regex pattern for matching the separator row
  static final RegExp _separatorPattern = RegExp(r'^\|?\s*:?-+:?\|.*$');

  /// Parse a table from the given markdown text.
  ///
  /// [markdown] The markdown text containing the table
  /// [startPosition] The position in the source text where the table starts
  ///
  /// Returns a [TableStructure] representing the parsed table, or null if
  /// the text doesn't contain a valid table
  TableStructure? parseTable(String markdown, {int startPosition = 0}) {
    final lines = markdown.split('\n');

    if (lines.length < 2) return null; // Need at least header and separator

    // Check if first line looks like a table row
    if (!_isTableRow(lines[0])) return null;

    // Check if second line is a separator
    if (!_isSeparatorRow(lines[1])) return null;

    // Parse header row
    final headerRow = _parseRow(lines[0], 0, isHeader: true);

    // Parse separator row to get column alignments
    final alignments = _parseAlignment(lines[1]);

    // Parse data rows (skip header and separator)
    final dataRows = <TableRow>[];
    for (int i = 2; i < lines.length; i++) {
      if (_isTableRow(lines[i])) {
        dataRows.add(_parseRow(lines[i], i - 1));
      } else {
        // End of table
        break;
      }
    }

    // Calculate end position
    int endPosition = startPosition;
    for (final line in lines) {
      endPosition += line.length + 1; // +1 for newline
    }

    return TableStructure(
      headerRow: headerRow,
      dataRows: dataRows,
      columnAlignments: alignments,
      startPosition: startPosition,
      endPosition: endPosition,
    );
  }

  /// Parse column alignments from a separator row.
  ///
  /// The separator row uses colons to indicate alignment:
  /// - `:---` or `---` : left alignment (default)
  /// - `:--:` : center alignment
  /// - `---:` : right alignment
  ///
  /// [separatorRow] The separator row text (e.g., `|---|:---:|---:|`)
  ///
  /// Returns a list of [ColumnAlignment] for each column
  List<ColumnAlignment> parseAlignment(String separatorRow) {
    return _parseAlignment(separatorRow);
  }

  /// Check if a line is a valid table row.
  ///
  /// [line] The line to check
  ///
  /// Returns true if the line looks like a table row (contains pipes)
  bool _isTableRow(String line) {
    return _rowPattern.hasMatch(line);
  }

  /// Check if a line is a separator row.
  ///
  /// [line] The line to check
  ///
  /// Returns true if the line is a valid separator row
  bool _isSeparatorRow(String line) {
    return _separatorPattern.hasMatch(line);
  }

  /// Parse a single table row.
  ///
  /// [line] The row text
  /// [rowIndex] The row index (0-based)
  /// [isHeader] Whether this is a header row
  ///
  /// Returns a [TableRow] representing the parsed row
  TableRow _parseRow(String line, int rowIndex, {bool isHeader = false}) {
    // Remove leading/trailing pipes and split by pipe
    final trimmed = line.trim();
    final withoutOuterPipes = trimmed.startsWith('|')
        ? (trimmed.endsWith('|') ? trimmed.substring(1, trimmed.length - 1) : trimmed.substring(1))
        : (trimmed.endsWith('|') ? trimmed.substring(0, trimmed.length - 1) : trimmed);

    final cellTexts = withoutOuterPipes.split('|');

    final cells = <TableCell>[];
    for (int i = 0; i < cellTexts.length; i++) {
      cells.add(TableCell(
        content: cellTexts[i].trim(),
        columnIndex: i,
        isHeader: isHeader,
      ));
    }

    return TableRow(
      cells: cells,
      rowIndex: rowIndex,
      isHeader: isHeader,
    );
  }

  /// Parse column alignments from a separator row.
  ///
  /// [separatorRow] The separator row text
  ///
  /// Returns a list of [ColumnAlignment] for each column
  List<ColumnAlignment> _parseAlignment(String separatorRow) {
    final trimmed = separatorRow.trim();
    final withoutOuterPipes = trimmed.startsWith('|')
        ? (trimmed.endsWith('|') ? trimmed.substring(1, trimmed.length - 1) : trimmed.substring(1))
        : (trimmed.endsWith('|') ? trimmed.substring(0, trimmed.length - 1) : trimmed);

    final separators = withoutOuterPipes.split('|');
    final alignments = <ColumnAlignment>[];

    for (final sep in separators) {
      final trimmedSep = sep.trim();
      if (trimmedSep.startsWith(':') && trimmedSep.endsWith(':')) {
        alignments.add(ColumnAlignment.center);
      } else if (trimmedSep.endsWith(':')) {
        alignments.add(ColumnAlignment.right);
      } else {
        alignments.add(ColumnAlignment.left);
      }
    }

    return alignments;
  }

  /// Find all tables in a markdown document.
  ///
  /// [markdown] The full markdown text
  ///
  /// Returns a list of [TableStructure] objects for all tables found
  List<TableStructure> findAllTables(String markdown) {
    final tables = <TableStructure>[];
    final lines = markdown.split('\n');

    int i = 0;
    while (i < lines.length) {
      // Look for potential table start
      if (_isTableRow(lines[i]) && i + 1 < lines.length && _isSeparatorRow(lines[i + 1])) {
        // Found a table, extract it
        final tableStart = i == 0 ? 0 : markdown.split('\n').sublist(0, i).join('\n').length + 1;

        // Find the end of the table
        int tableEnd = i + 2;
        while (tableEnd < lines.length && _isTableRow(lines[tableEnd])) {
          tableEnd++;
        }

        // Extract the table text
        final tableLines = lines.sublist(i, tableEnd);
        final tableText = tableLines.join('\n');

        // Parse the table
        final table = parseTable(tableText, startPosition: tableStart);
        if (table != null) {
          tables.add(table);
        }

        i = tableEnd;
      } else {
        i++;
      }
    }

    return tables;
  }

  /// Create markdown tokens for all tables in the document.
  ///
  /// [markdown] The full markdown text
  ///
  /// Returns a list of [MarkdownToken] objects for all tables
  List<MarkdownToken> createTableTokens(String markdown) {
    final tables = findAllTables(markdown);
    final tokens = <MarkdownToken>[];

    for (final table in tables) {
      tokens.add(MarkdownToken(
        type: 'table',
        start: table.startPosition,
        end: table.endPosition,
        content: markdown.substring(table.startPosition, table.endPosition),
        metadata: {
          'columnCount': table.columnCount,
          'rowCount': table.rowCount,
          'hasHeader': table.hasHeader,
        },
      ));
    }

    return tokens;
  }
}
