import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../core/utils/prefix_parser.dart';

class PrefixText extends StatelessWidget {
  const PrefixText({
    super.key,
    required this.content,
    required this.index,
    this.highlightQuery,
  });

  final String content;
  final int index;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final prefix = parsePrefix(content);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium!;
    final prefixColor = _prefixColor(context, prefix ?? '');
    final remainder = prefix == null
        ? content
        : content.substring(prefix.length);
    final rendered = RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          if (prefix != null)
            TextSpan(
              text: prefix,
              style: bodyStyle.copyWith(
                color: prefixColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ..._highlightedSpans(context, remainder, bodyStyle),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: content,
      child: ExcludeSemantics(child: rendered),
    );
  }

  List<TextSpan> _highlightedSpans(
    BuildContext context,
    String text,
    TextStyle bodyStyle,
  ) {
    final query = highlightQuery?.trim();
    if (query == null || query.isEmpty) return [TextSpan(text: text)];

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: bodyStyle.copyWith(
            backgroundColor: tideColorsOf(context).accentSubtle,
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }

  Color _prefixColor(BuildContext context, String prefix) {
    final g = tideColorsOf(context);
    final palette = [g.accent, g.rescue, g.textSecondary];
    return palette[prefixPaletteIndex(prefix, palette.length)];
  }
}
