import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'design_helpers.dart';

/// A single, restrained line-art glyph used for the Archive and Deleted
/// Notes empty states — Tide's own water motif, not a decorative brand
/// asset, rendered at low opacity in the current theme's muted tone.
class TideEmptyIllustration extends StatelessWidget {
  const TideEmptyIllustration({super.key, required this.icon});

  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    return FaIcon(icon, size: 40, color: g.lineStrong);
  }
}
