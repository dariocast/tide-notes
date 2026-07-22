import 'package:flutter/material.dart';

/// Design System v2.0 — the single source of visual values.
abstract final class GFoam {
  static const bgTop = Color(0xFFF7FBFC);
  static const bgMid = Color(0xFFEEF6F7);
  static const bgBottom = Color(0xFFE3EFF1);
  static const surface = Color(0xFFFAFDFD);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const ink = Color(0xFF102F3A);
  static const textSecondary = Color(0xFF214A55);
  static const textMuted = Color(0xFF1E424B);
  static const accent = Color(0xFF1A7180);
  static const accentMuted = Color(0xFF69AAB3);
  static const accentSubtle = Color(0xFFD7EAED);
  static const textOnAccent = Color(0xFFF6FCFD);
  static const rescue = Color(0xFF3F7F72);
  static const rescueSoft = Color(0xFFD9EBE6);
  static const prefixWarm = Color(0xFFAD6A66);
  static const danger = Color(0xFFA9565B);
  static const dangerSoft = Color(0xFFF4E1E3);
  static const lineSubtle = Color(0x1F102F3A);
  static const lineStrong = Color(0x52102F3A);
  static const depthFloor = 0.80;
}

abstract final class GDeepTide {
  static const bgTop = Color(0xFF0C242B);
  static const bgMid = Color(0xFF081C22);
  static const bgBottom = Color(0xFF041319);
  static const surface = Color(0xFF0B232A);
  static const surfaceElevated = Color(0xFF102C34);
  static const ink = Color(0xFFE8F4F5);
  static const textSecondary = Color(0xFFC6DEE1);
  static const textMuted = Color(0xFFA7C3C8);
  static const accent = Color(0xFF55A9B5);
  static const accentMuted = Color(0xFF477C85);
  static const accentSubtle = Color(0xFF183B43);
  static const textOnAccent = Color(0xFF04171C);
  static const rescue = Color(0xFF6AAE9E);
  static const rescueSoft = Color(0xFF173B35);
  static const prefixWarm = Color(0xFFC1847F);
  static const danger = Color(0xFFD78386);
  static const dangerSoft = Color(0xFF3A2025);
  static const lineSubtle = Color(0x24E8F4F5);
  static const lineStrong = Color(0x5CE8F4F5);
  static const depthFloor = 0.72;
}

abstract final class GAbyss {
  static const bgTop = Colors.black;
  static const bgMid = Colors.black;
  static const bgBottom = Colors.black;
  static const surface = Colors.black;
  static const surfaceElevated = Color(0xFF071419);
  static const ink = Color(0xFFEDF8F8);
  static const textSecondary = Color(0xFFC9E1E3);
  static const textMuted = Color(0xFFA8C6C8);
  static const accent = Color(0xFF62B2BD);
  static const accentMuted = Color(0xFF4A7E86);
  static const accentSubtle = Color(0xFF102D33);
  static const textOnAccent = Color(0xFF001014);
  static const rescue = Color(0xFF70B5A5);
  static const rescueSoft = Color(0xFF102F29);
  static const prefixWarm = Color(0xFFC98B86);
  static const danger = Color(0xFFE18A8E);
  static const dangerSoft = Color(0xFF35191E);
  static const lineSubtle = Color(0x2AEDF8F8);
  static const lineStrong = Color(0x66EDF8F8);
  static const depthFloor = 0.70;
}

abstract final class GSpace {
  static const s1 = 4.0,
      s2 = 8.0,
      s3 = 12.0,
      s4 = 16.0,
      s5 = 24.0,
      s6 = 32.0,
      s7 = 48.0,
      s8 = 72.0,
      s9 = 96.0;
}

abstract final class GLayout {
  static const contentMax = 720.0,
      contentNarrow = 640.0,
      contentWide = 800.0,
      desktopMax = 1040.0,
      desktopSidebar = 336.0,
      headerHeight = 72.0,
      minTouchTarget = 48.0,
      bpMedium = 600.0,
      bpExpanded = 840.0;
}

abstract final class GDecor {
  static const crossSize = 19.0,
      crossThickness = 1.0,
      crossOffset = 14.0,
      railWidth = 2.5,
      hairline = 1.0;
  static const hoverAlpha = 0.05,
      pressAlpha = 0.09,
      bloomAlpha = 0.55,
      swipeGlyphAlpha = 0.16;
}

abstract final class GMotion {
  static const settle = Cubic(0.16, 0.99, 0.26, 1);
  static const colorFast = Duration(milliseconds: 120),
      color = Duration(milliseconds: 150),
      colorSlow = Duration(milliseconds: 180),
      panel = Duration(milliseconds: 320),
      move = Duration(milliseconds: 380),
      enterOpacity = Duration(milliseconds: 460),
      enterMove = Duration(milliseconds: 560),
      flash = Duration(milliseconds: 960),
      float = Duration(seconds: 16);
}

abstract final class GShadows {
  static const shadowSoft = BoxShadow(
    color: Color(0x141A1714),
    blurRadius: 40,
    offset: Offset(0, 14),
  );
  static const shadowRaise = BoxShadow(
    color: Color(0x1F1A1714),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}

abstract final class GRadii {
  static const control = 14.0;
  static const composer = 20.0;
  static const pill = 999.0;
}

abstract final class GShapes {
  static const control = BorderRadius.all(Radius.circular(GRadii.control));
  static const composer = BorderRadius.all(Radius.circular(GRadii.composer));
  static const pill = BorderRadius.all(Radius.circular(GRadii.pill));
}

@immutable
class TideColors extends ThemeExtension<TideColors> {
  const TideColors({
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentMuted,
    required this.accentSubtle,
    required this.textOnAccent,
    required this.rescue,
    required this.rescueSoft,
    required this.prefixWarm,
    required this.danger,
    required this.dangerSoft,
    required this.lineSubtle,
    required this.lineStrong,
    required this.isOled,
    required this.depthFloor,
  });
  final Color bgTop,
      bgMid,
      bgBottom,
      surface,
      surfaceElevated,
      ink,
      textSecondary,
      textMuted,
      accent,
      accentMuted,
      accentSubtle,
      textOnAccent,
      rescue,
      rescueSoft,
      prefixWarm,
      danger,
      dangerSoft,
      lineSubtle,
      lineStrong;
  final bool isOled;
  final double depthFloor;

  static const foam = TideColors(
    bgTop: GFoam.bgTop,
    bgMid: GFoam.bgMid,
    bgBottom: GFoam.bgBottom,
    surface: GFoam.surface,
    surfaceElevated: GFoam.surfaceElevated,
    ink: GFoam.ink,
    textSecondary: GFoam.textSecondary,
    textMuted: GFoam.textMuted,
    accent: GFoam.accent,
    accentMuted: GFoam.accentMuted,
    accentSubtle: GFoam.accentSubtle,
    textOnAccent: GFoam.textOnAccent,
    rescue: GFoam.rescue,
    rescueSoft: GFoam.rescueSoft,
    prefixWarm: GFoam.prefixWarm,
    danger: GFoam.danger,
    dangerSoft: GFoam.dangerSoft,
    lineSubtle: GFoam.lineSubtle,
    lineStrong: GFoam.lineStrong,
    isOled: false,
    depthFloor: GFoam.depthFloor,
  );
  static const deepTide = TideColors(
    bgTop: GDeepTide.bgTop,
    bgMid: GDeepTide.bgMid,
    bgBottom: GDeepTide.bgBottom,
    surface: GDeepTide.surface,
    surfaceElevated: GDeepTide.surfaceElevated,
    ink: GDeepTide.ink,
    textSecondary: GDeepTide.textSecondary,
    textMuted: GDeepTide.textMuted,
    accent: GDeepTide.accent,
    accentMuted: GDeepTide.accentMuted,
    accentSubtle: GDeepTide.accentSubtle,
    textOnAccent: GDeepTide.textOnAccent,
    rescue: GDeepTide.rescue,
    rescueSoft: GDeepTide.rescueSoft,
    prefixWarm: GDeepTide.prefixWarm,
    danger: GDeepTide.danger,
    dangerSoft: GDeepTide.dangerSoft,
    lineSubtle: GDeepTide.lineSubtle,
    lineStrong: GDeepTide.lineStrong,
    isOled: false,
    depthFloor: GDeepTide.depthFloor,
  );
  static const abyss = TideColors(
    bgTop: GAbyss.bgTop,
    bgMid: GAbyss.bgMid,
    bgBottom: GAbyss.bgBottom,
    surface: GAbyss.surface,
    surfaceElevated: GAbyss.surfaceElevated,
    ink: GAbyss.ink,
    textSecondary: GAbyss.textSecondary,
    textMuted: GAbyss.textMuted,
    accent: GAbyss.accent,
    accentMuted: GAbyss.accentMuted,
    accentSubtle: GAbyss.accentSubtle,
    textOnAccent: GAbyss.textOnAccent,
    rescue: GAbyss.rescue,
    rescueSoft: GAbyss.rescueSoft,
    prefixWarm: GAbyss.prefixWarm,
    danger: GAbyss.danger,
    dangerSoft: GAbyss.dangerSoft,
    lineSubtle: GAbyss.lineSubtle,
    lineStrong: GAbyss.lineStrong,
    isOled: true,
    depthFloor: GAbyss.depthFloor,
  );

  @override
  TideColors copyWith() => this;

  @override
  TideColors lerp(TideColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TideColors(
      bgTop: l(bgTop, other.bgTop),
      bgMid: l(bgMid, other.bgMid),
      bgBottom: l(bgBottom, other.bgBottom),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      ink: l(ink, other.ink),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentMuted: l(accentMuted, other.accentMuted),
      accentSubtle: l(accentSubtle, other.accentSubtle),
      textOnAccent: l(textOnAccent, other.textOnAccent),
      rescue: l(rescue, other.rescue),
      rescueSoft: l(rescueSoft, other.rescueSoft),
      prefixWarm: l(prefixWarm, other.prefixWarm),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      lineSubtle: l(lineSubtle, other.lineSubtle),
      lineStrong: l(lineStrong, other.lineStrong),
      isOled: t < 0.5 ? isOled : other.isOled,
      depthFloor: depthFloor + (other.depthFloor - depthFloor) * t,
    );
  }
}
