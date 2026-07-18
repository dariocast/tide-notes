import 'package:flutter/material.dart';

import '../../core/theme/tide_colors.dart';
import '../../core/utils/prefix_parser.dart';

class PrefixText extends StatelessWidget {
  const PrefixText({super.key, required this.content, required this.index});

  final String content;
  final int index;

  @override
  Widget build(BuildContext context) {
    final prefix = parsePrefix(content);
    final bodyStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 17, height: 1.45);
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
              style: TextStyle(color: prefixColor, fontWeight: FontWeight.w700),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark
        ? const [Color(0xFFB7D7DE), TideColors.moon, Color(0xFFE2CAA2)]
        : const [TideColors.ink, Color(0xFF315D70), Color(0xFF6A5434)];
    return palette[prefixPaletteIndex(prefix, palette.length)];
  }
}
