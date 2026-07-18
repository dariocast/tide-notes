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
    final colors = _palette(context, prefix ?? '');
    final text = RichText(
      text: TextSpan(
        style: TextStyle(color: colors.fallback, fontSize: 17, height: 1.45),
        children: [
          if (prefix == null)
            TextSpan(text: content)
          else ...[
            TextSpan(
              text: prefix,
              style: TextStyle(
                color: colors.fallback,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: content.substring(prefix.length)),
          ],
        ],
      ),
    );

    final rendered = prefix == null
        ? text
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                LinearGradient(colors: colors.gradient).createShader(bounds),
            child: text,
          );

    return Semantics(
      container: true,
      label: content,
      child: ExcludeSemantics(child: rendered),
    );
  }

  _PrefixColors _palette(BuildContext context, String prefix) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark
        ? const [
            [TideColors.moon, TideColors.darkMuted],
            [Color(0xFFB7D7DE), TideColors.moon],
            [TideColors.darkMuted, Color(0xFFDAE9EC)],
          ]
        : const [
            [TideColors.ink, Color(0xFF2B586B)],
            [Color(0xFF315D70), TideColors.ink],
            [Color(0xFF264D5E), Color(0xFF496F7D)],
          ];
    final colors = palette[prefixPaletteIndex(prefix, palette.length)];
    return _PrefixColors(gradient: colors, fallback: colors.first);
  }
}

final class _PrefixColors {
  const _PrefixColors({required this.gradient, required this.fallback});

  final List<Color> gradient;
  final Color fallback;
}
