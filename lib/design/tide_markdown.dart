import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'design_helpers.dart';
import 'design_tokens.dart';

/// Maps Tide's existing typography and palette tokens onto the markdown
/// renderer so a theme switch restyles rendered note content automatically,
/// without a second set of colors/fonts to keep in sync.
MarkdownStyleSheet tideMarkdownStyleSheet(BuildContext context) {
  final g = tideColorsOf(context);
  final text = Theme.of(context).textTheme;

  return MarkdownStyleSheet(
    h1: text.headlineMedium,
    h2: text.titleLarge,
    p: text.bodyMedium,
    strong: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    em: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
    code: text.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      backgroundColor: g.accentSubtle,
    ),
    codeblockDecoration: BoxDecoration(
      color: g.accentSubtle,
      borderRadius: GShapes.control,
    ),
    blockquote: text.bodyMedium?.copyWith(color: g.textMuted),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: g.lineSubtle, width: 3)),
    ),
    listBullet: text.bodyMedium?.copyWith(color: g.accent),
    blockSpacing: GSpace.s2,
  );
}
