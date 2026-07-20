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

/// The Tide wordmark glyph — two nested crests drawn as one continuous stroke,
/// evoking a receding tide. Purely decorative; excluded from semantics.
class TideGlyph extends StatelessWidget {
  const TideGlyph({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? gravityOf(context).accent;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size * 1.35, size),
        painter: _TideGlyphPainter(tint),
      ),
    );
  }
}

class _TideGlyphPainter extends CustomPainter {
  const _TideGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = GDecor.glyphStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;
    void crest(double y, Color c) {
      canvas.drawPath(
        Path()
          ..moveTo(0, y)
          ..cubicTo(w * 0.28, y - h * 0.42, w * 0.42, y + h * 0.30, w * 0.5, y)
          ..cubicTo(w * 0.62, y - h * 0.30, w * 0.78, y + h * 0.42, w, y),
        paint..color = c,
      );
    }

    crest(h * 0.34, color.withValues(alpha: 0.45));
    crest(h * 0.70, color);
  }

  @override
  bool shouldRepaint(_TideGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Editorial corner-marks framing a region, drawn from [GDecor] so the
/// masthead reads as a deliberately composed page rather than a raw column.
class MastheadFrame extends StatelessWidget {
  const MastheadFrame({super.key, required this.child, this.inset});

  final Widget child;
  final double? inset;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _CornerMarkPainter(
      color: gravityOf(context).cornerInk,
      inset: inset ?? GDecor.frameInset,
    ),
    child: child,
  );
}

class _CornerMarkPainter extends CustomPainter {
  const _CornerMarkPainter({required this.color, required this.inset});

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = GDecor.cornerMarkThickness;
    const len = GDecor.cornerMarkLength;
    final l = inset, t = inset, r = size.width - inset, b = size.height - inset;
    void corner(double x, double y, double dx, double dy) => canvas
      ..drawLine(Offset(x, y), Offset(x + dx, y), paint)
      ..drawLine(Offset(x, y), Offset(x, y + dy), paint);
    corner(l, t, len, len); // top-left
    corner(r, t, -len, len); // top-right
    corner(l, b, len, -len); // bottom-left
    corner(r, b, -len, -len); // bottom-right
  }

  @override
  bool shouldRepaint(_CornerMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.inset != inset;
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
