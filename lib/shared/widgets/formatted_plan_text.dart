import 'package:flutter/material.dart';

/// Renders a single line of workout/diet plan text, understanding a small
/// custom tag syntax authored on the backend: <title>, <bullet>, <b>, <i>,
/// <underline>. Lines with no recognized tags render as plain text, exactly
/// as before — this is purely additive formatting.
class FormattedPlanLine extends StatelessWidget {
  final String raw;
  final TextStyle baseStyle;

  const FormattedPlanLine({
    super.key,
    required this.raw,
    required this.baseStyle,
  });

  static const _titleColor = Color(0xFFFF7A1A);

  static final _titleBlockPattern =
      RegExp(r'^<title>([\s\S]*)</title>$', caseSensitive: false);
  static final _bulletBlockPattern =
      RegExp(r'^<bullet>([\s\S]*)</bullet>$', caseSensitive: false);
  static final _anyTagPattern = RegExp(
      r'</?(title|bullet|b|i|underline)>',
      caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    try {
      return _buildSafe();
    } catch (_) {
      return Text(_stripTags(raw), style: baseStyle);
    }
  }

  Widget _buildSafe() {
    final line = raw.trim();

    final titleMatch = _titleBlockPattern.firstMatch(line);
    if (titleMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          _stripTags(titleMatch.group(1)!).trim().toUpperCase(),
          style: baseStyle.copyWith(
            color: _titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final bulletMatch = _bulletBlockPattern.firstMatch(line);
    if (bulletMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: baseStyle),
            Expanded(
              child: Text.rich(
                TextSpan(children: _parseInlineSpans(bulletMatch.group(1)!)),
              ),
            ),
          ],
        ),
      );
    }

    return Text.rich(TextSpan(children: _parseInlineSpans(line)));
  }

  List<InlineSpan> _parseInlineSpans(String text) {
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    bool bold = false;
    bool italic = false;
    bool underline = false;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(
        text: buffer.toString(),
        style: baseStyle.copyWith(
          fontWeight: bold ? FontWeight.bold : baseStyle.fontWeight,
          fontStyle: italic ? FontStyle.italic : baseStyle.fontStyle,
          decoration: underline ? TextDecoration.underline : baseStyle.decoration,
        ),
      ));
      buffer.clear();
    }

    final tagPattern = RegExp(r'<(/?)(b|i|underline)>', caseSensitive: false);
    int cursor = 0;
    for (final match in tagPattern.allMatches(text)) {
      buffer.write(text.substring(cursor, match.start));
      flush();
      final closing = match.group(1) == '/';
      final tag = match.group(2)!.toLowerCase();
      final value = !closing;
      switch (tag) {
        case 'b':
          bold = value;
          break;
        case 'i':
          italic = value;
          break;
        case 'underline':
          underline = value;
          break;
      }
      cursor = match.end;
    }
    buffer.write(text.substring(cursor));
    flush();

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    return spans;
  }

  String _stripTags(String text) => text.replaceAll(_anyTagPattern, '');
}
