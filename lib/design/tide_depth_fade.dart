import 'package:flutter/material.dart';

import 'design_helpers.dart';
import 'design_tokens.dart';

/// Pure viewport-relative depth math for the Tide note stream.
///
/// The top 65% of the visible viewport renders at full presence; the
/// remaining bottom band fades smoothly toward a theme-specific floor.
abstract final class TideDepthModel {
  static const fullPresenceEnd = 0.65;

  /// Opacity for content sitting at [viewportFraction] (0 = top of the
  /// viewport, 1 = bottom), fading toward [floor] past [fullPresenceEnd].
  static double opacityAt(double viewportFraction, {required double floor}) {
    final fraction = viewportFraction.clamp(0.0, 1.0);
    if (fraction <= fullPresenceEnd) return 1;
    final progress = (fraction - fullPresenceEnd) / (1 - fullPresenceEnd);
    return 1 - ((1 - floor) * progress);
  }
}

/// Wraps the scrolling note stream with a bottom-only alpha gradient so
/// notes sink toward the theme floor as they approach the bottom of the
/// viewport, recovering full presence as they scroll upward.
///
/// Disabled while inline editing is active (context/editor stability) and
/// under high-contrast mode (accessibility). A single [ShaderMask] keeps
/// this cheap and compatible with a lazy `ListView.builder` beneath it.
class TideDepthFade extends StatelessWidget {
  const TideDepthFade({super.key, required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = tideColorsOf(context);
    if (!enabled || MediaQuery.highContrastOf(context)) return child;
    return ShaderMask(
      key: const ValueKey('tide-depth-mask'),
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => buildGradient(colors).createShader(bounds),
      child: child,
    );
  }

  /// The bottom-only alpha gradient used to mask [child]: full presence
  /// (opaque white) through [TideDepthModel.fullPresenceEnd] of the
  /// viewport, then fading toward the theme's [TideColors.depthFloor] by
  /// the bottom. Extracted so the gradient's direction and stops can be
  /// asserted on directly, independent of rendering.
  @visibleForTesting
  static LinearGradient buildGradient(TideColors colors) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white,
      Colors.white,
      Colors.white.withValues(alpha: colors.depthFloor),
    ],
    stops: const [0, TideDepthModel.fullPresenceEnd, 1],
  );
}
