import 'package:flutter/material.dart';

import '../../design/design_tokens.dart';
import '../../core/utils/prefix_parser.dart';

class PrefixText extends StatelessWidget {
  const PrefixText({super.key, required this.content, required this.index});

  final String content;
  final int index;

  @override
  Widget build(BuildContext context) {
    final prefix = parsePrefix(content);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium!;
    final prefixColor = _prefixColor(context, prefix ?? '');
    final rendered = RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          if (prefix == null)
            TextSpan(text: content)
          else ...[
            TextSpan(
              text: prefix,
              style: bodyStyle.copyWith(
                color: prefixColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: content.substring(prefix.length)),
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      label: content,
      child: ExcludeSemantics(child: rendered),
    );
  }

  Color _prefixColor(BuildContext context, String prefix) {
    final g = Theme.of(context).extension<TideColors>()!;
    final palette = [g.accent, g.rescue, g.prefixWarm];
    return palette[prefixPaletteIndex(prefix, palette.length)];
  }
}
