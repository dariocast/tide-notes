import 'package:flutter/material.dart';

import 'appearance_controller.dart';
import 'design_tokens.dart';

enum GSizeClass { compact, medium, expanded }

GSizeClass sizeClassOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= GLayout.bpExpanded) return GSizeClass.expanded;
  if (width >= GLayout.bpMedium) return GSizeClass.medium;
  return GSizeClass.compact;
}

class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g =
        Theme.of(context).extension<GravityTheme>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? GravityTheme.dark
            : GravityTheme.light);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [g.bgTop, g.bgMid, g.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

class GravityMotion {
  const GravityMotion(this.context);

  final BuildContext context;

  Duration duration(Duration value) =>
      MediaQuery.disableAnimationsOf(context) ||
          !(AppearanceScope.maybeOf(context)?.motionEnabled ?? true)
      ? GMotion.colorFast
      : value;
}

extension GravityContext on BuildContext {
  GravityMotion get motion => GravityMotion(this);
}

class FocusRing extends StatelessWidget {
  const FocusRing({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = Theme.of(context).extension<GravityTheme>()!;
    return Focus(
      child: Builder(
        builder: (context) => AnimatedContainer(
          duration: context.motion.duration(GMotion.color),
          curve: GMotion.settle,
          decoration: BoxDecoration(
            border: Focus.of(context).hasFocus
                ? Border.all(color: g.rescue.withValues(alpha: .9), width: 2)
                : null,
            boxShadow: Focus.of(context).hasFocus
                ? [
                    BoxShadow(
                      color: g.rescue.withValues(alpha: .28),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
