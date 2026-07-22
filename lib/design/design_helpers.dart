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

/// Resolves the Gravity palette, falling back to the brightness default so
/// widgets never crash when the extension is momentarily absent.
GravityTheme gravityOf(BuildContext context) =>
    Theme.of(context).extension<GravityTheme>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? GravityTheme.dark
        : GravityTheme.light);

class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = gravityOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [g.bgTop, g.bgMid, g.bgBottom],
        ),
      ),
      // A soft luminous bloom lifts the top-centre of the paper, giving the
      // flat gradient a sense of being lit from above the masthead.
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.85),
            radius: 1.15,
            colors: [
              g.surfaceElevated.withValues(alpha: GDecor.bloomAlpha),
              g.surfaceElevated.withValues(alpha: 0),
            ],
            stops: const [0, 0.62],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A single tokenized hairline rule.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: indent),
    child: SizedBox(
      height: GDecor.hairline,
      width: double.infinity,
      child: ColoredBox(color: gravityOf(context).lineSubtle),
    ),
  );
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
    final g = gravityOf(context);
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
