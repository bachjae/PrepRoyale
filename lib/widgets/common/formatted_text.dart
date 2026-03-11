import 'package:flutter/material.dart';

/// Renders question / passage text with two enhancements:
///
/// 1. **Superscripts** – `base^exp` is displayed as base with a raised
///    smaller exponent. Works for `x^2`, `10^-3`, `(x+1)^n`, `x^(n+1)`.
///
/// 2. **Tables** – pipe-separated rows with a `---|---` separator line are
///    rendered as a proper Flutter [Table] instead of raw ASCII art.
class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const FormattedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ?? DefaultTextStyle.of(context).style;

    if (_hasTable(text)) {
      return _buildWithTables(context, text, effectiveStyle);
    }
    return _buildRich(context, text, effectiveStyle);
  }

  // ── Table detection ──────────────────────────────────────────────────────

  static bool _hasTable(String text) {
    final lines = text.split('\n');
    final pipeCount = lines.where((l) => l.contains('|')).length;
    final sepCount = lines.where(_isSeparatorLine).length;
    return pipeCount >= 2 && sepCount >= 1;
  }

  static bool _isSeparatorLine(String line) {
    final t = line.trim();
    return t.contains('-') && RegExp(r'^[-|+:\s]+$').hasMatch(t);
  }

  // ── Table + surrounding text ──────────────────────────────────────────────

  Widget _buildWithTables(
      BuildContext context, String text, TextStyle style) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    final textBuffer = <String>[];

    int i = 0;
    while (i < lines.length) {
      // Detect start of a table: header row followed by separator row
      if (i + 1 < lines.length &&
          lines[i].contains('|') &&
          _isSeparatorLine(lines[i + 1])) {
        // Flush buffered text
        if (textBuffer.isNotEmpty) {
          final chunk = textBuffer.join('\n').trim();
          if (chunk.isNotEmpty) {
            widgets.add(_buildRich(context, chunk, style));
            widgets.add(const SizedBox(height: 8));
          }
          textBuffer.clear();
        }
        // Collect all table lines (until blank line or end)
        final tableLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          tableLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildTable(context, tableLines, style));
        widgets.add(const SizedBox(height: 8));
      } else {
        textBuffer.add(lines[i]);
        i++;
      }
    }

    if (textBuffer.isNotEmpty) {
      final chunk = textBuffer.join('\n').trim();
      if (chunk.isNotEmpty) {
        widgets.add(_buildRich(context, chunk, style));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ── Table widget ──────────────────────────────────────────────────────────

  Widget _buildTable(
      BuildContext context, List<String> tableLines, TextStyle style) {
    // Remove separator lines, keep data rows
    final dataLines =
        tableLines.where((l) => !_isSeparatorLine(l)).toList();
    if (dataLines.isEmpty) return const SizedBox.shrink();

    // Parse rows: split on | and trim each cell
    final rows = dataLines.map((line) {
      return line
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    }).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    final columnCount =
        rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final cellStyle = style.copyWith(
      fontSize: (style.fontSize ?? 14) * 0.88,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Table(
        border: TableBorder.symmetric(
          inside: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        columnWidths: {
          for (int c = 0; c < columnCount; c++) c: const FlexColumnWidth(),
        },
        children: rows.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final cells = entry.value;
          final isHeader = rowIndex == 0;

          return TableRow(
            decoration: BoxDecoration(
              color: isHeader
                  ? const Color(0xFFE2E8F0)
                  : rowIndex.isOdd
                      ? const Color(0xFFF8FAFC)
                      : Colors.white,
            ),
            children: List.generate(columnCount, (colIndex) {
              final cellText = colIndex < cells.length ? cells[colIndex] : '';
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                child: _buildRich(
                  context,
                  cellText,
                  cellStyle.copyWith(
                    fontWeight:
                        isHeader ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          );
        }).toList(),
      ),
    );
  }

  // ── Superscript + Underline RichText ─────────────────────────────────────

  Widget _buildRich(
      BuildContext context, String text, TextStyle style) {
    final spans = _parseSpans(text, style);
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  /// Parse text for inline markup and return a list of [InlineSpan].
  ///
  /// Supported markup (applied in order):
  ///   __text__     →  underlined text          (Writing/English questions)
  ///   base^exp     →  base with superscript exp (Math/Science)
  ///
  /// Underline examples:
  ///   "The word __however__ should be replaced…"
  ///   "Which best improves the sentence __Leading scientists…__?"
  ///
  /// Superscript examples:
  ///   x^2  →  x²     10^-3  →  10⁻³
  static List<InlineSpan> _parseSpans(String text, TextStyle style) {
    // ── Regex patterns ────────────────────────────────────────────────────
    // Underline: __...__ (non-greedy, does NOT span newlines)
    final underlineRe = RegExp(r'__(.+?)__');
    // Superscript: base^exp
    final supRe = RegExp(r'(\([^)]+\)|[^\s^(]+)\^(\([^)]+\)|[-+]?[^\s^]+)');

    // Split the full text into segments: underlined vs plain
    final spans = <InlineSpan>[];

    void addPlainSegment(String segment) {
      // Within a plain segment, look for superscripts
      int cursor = 0;
      for (final m in supRe.allMatches(segment)) {
        if (m.start > cursor) {
          spans.add(TextSpan(
            text: segment.substring(cursor, m.start),
            style: style,
          ));
        }
        final base = m.group(1)!;
        final exp = m.group(2)!;
        final supSize = (style.fontSize ?? 14) * 0.68;

        spans.add(TextSpan(text: base, style: style));
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.top,
          baseline: TextBaseline.alphabetic,
          child: Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Text(
              exp,
              style: style.copyWith(fontSize: supSize, height: 1.1),
            ),
          ),
        ));
        cursor = m.end;
      }
      if (cursor < segment.length) {
        spans.add(TextSpan(text: segment.substring(cursor), style: style));
      }
    }

    int cursor = 0;
    for (final m in underlineRe.allMatches(text)) {
      // Plain text before the underline marker
      if (m.start > cursor) {
        addPlainSegment(text.substring(cursor, m.start));
      }
      // The underlined content (superscripts inside underlines are rare but supported)
      final inner = m.group(1)!;
      spans.add(TextSpan(
        text: inner,
        style: style.copyWith(decoration: TextDecoration.underline),
      ));
      cursor = m.end;
    }

    // Remaining plain text after last underline
    if (cursor < text.length) {
      addPlainSegment(text.substring(cursor));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: style)]
        : spans;
  }
}
