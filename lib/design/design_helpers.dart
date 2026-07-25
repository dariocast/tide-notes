import 'package:flutter/material.dart';

import 'design_tokens.dart';

enum GSizeClass { compact, medium, expanded }

GSizeClass sizeClassOf(BuildContext context) {
  final override = GSizeClassScope.maybeOf(context);
  if (override != null) return override;

  final width = MediaQuery.sizeOf(context).width;
  if (width >= GLayout.bpExpanded) return GSizeClass.expanded;
  if (width >= GLayout.bpMedium) return GSizeClass.medium;
  return GSizeClass.compact;
}

/// Overrides responsive spacing for a focused layout subtree.
class GSizeClassScope extends InheritedWidget {
  const GSizeClassScope({
    super.key,
    required this.sizeClass,
    required super.child,
  });

  final GSizeClass sizeClass;

  static GSizeClass? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GSizeClassScope>()?.sizeClass;

  @override
  bool updateShouldNotify(GSizeClassScope oldWidget) =>
      sizeClass != oldWidget.sizeClass;
}

/// Resolves the Tide palette, falling back to the brightness default so
/// widgets never crash when the extension is momentarily absent.
TideColors tideColorsOf(BuildContext context) =>
    Theme.of(context).extension<TideColors>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? TideColors.deepTide
        : TideColors.foam);

class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    if (g.isOled) return ColoredBox(color: Colors.black, child: child);
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
      child: ColoredBox(color: tideColorsOf(context).lineSubtle),
    ),
  );
}

class TideMotionPolicy {
  const TideMotionPolicy(this.context);

  final BuildContext context;

  bool get reduceMotion => MediaQuery.disableAnimationsOf(context);

  Duration duration(Duration normal) => reduceMotion ? Duration.zero : normal;
}

extension TideContext on BuildContext {
  TideMotionPolicy get motion => TideMotionPolicy(this);
}

/// A restrained focus outline: a 2px accent-colored border with no glow or
/// shadow. Pass [borderRadius] to match a rounded surface underneath; leave
/// it null for flat surfaces such as note rows.
class FocusRing extends StatelessWidget {
  const FocusRing({super.key, required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    return Focus(
      child: Builder(
        builder: (context) => AnimatedContainer(
          duration: context.motion.duration(GMotion.color),
          curve: GMotion.settle,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Focus.of(context).hasFocus
                ? Border.all(color: g.accent, width: 2)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
