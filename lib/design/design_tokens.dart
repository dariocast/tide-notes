import 'package:flutter/material.dart';

/// Design System v2.0 — the single source of visual values.
abstract final class GLight {
  static const bgTop = Color(0xFFF8F4EF);
  static const bgMid = Color(0xFFF5EFE6);
  static const bgBottom = Color(0xFFECE1D5);
  static const surface = Color(0xFFFBF9F7);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1714);
  static const textSecondary = Color(0xFF332C25);
  static const textMuted = Color(0xFF51483F);
  static const textGhost = Color(0xFF7A7067);
  static const dotNeutral = Color(0xFF3F352B);
  static const accent = Color(0xFF9D6B3D);
  static const accentMuted = Color(0xFFC9A67A);
  static const accentSubtle = Color(0xFFE8DED0);
  static const textOnAccent = Color(0xFFFFFAF3);
  static const rescue = Color(0xFF6B8C5A);
  static const rescueSoft = Color(0xFFD4E4CD);
  static const archive = Color(0xFF7C8A9C);
  static const archiveSoft = Color(0xFFE0E4EA);
  static const danger = Color(0xFFB85450);
  static const dangerSoft = Color(0xFFF5E0DF);
  static const lineSubtle = Color(0x1F1A1714);
  static const lineStrong = Color(0x611A1714);
  static const cornerInk = Color(0x571A1714);
}

abstract final class GDark {
  static const bgTop = Color(0xFF1B1713);
  static const bgMid = Color(0xFF171310);
  static const bgBottom = Color(0xFF120F0C);
  static const surface = Color(0xFF201B16);
  static const surfaceElevated = Color(0xFF262019);
  static const ink = Color(0xFFF0EAE2);
  static const textSecondary = Color(0xFFD5CCC1);
  static const textMuted = Color(0xFFA79C8F);
  static const textGhost = Color(0xFF7E756B);
  static const dotNeutral = Color(0xFFC9BEB1);
  static const accent = Color(0xFFC08B58);
  static const accentMuted = Color(0xFF8A6A48);
  static const accentSubtle = Color(0xFF33291F);
  static const textOnAccent = Color(0xFF1A1714);
  static const rescue = Color(0xFF8FAF7E);
  static const rescueSoft = Color(0xFF2A3324);
  static const archive = Color(0xFF93A2B4);
  static const archiveSoft = Color(0xFF262B31);
  static const danger = Color(0xFFD07A75);
  static const dangerSoft = Color(0xFF392422);
  static const lineSubtle = Color(0x1FF0EAE2);
  static const lineStrong = Color(0x61F0EAE2);
  static const cornerInk = Color(0x57F0EAE2);
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
      headerHeight = 72.0,
      minTouchTarget = 48.0,
      bpMedium = 600.0,
      bpExpanded = 840.0;
}

abstract final class GDecor {
  static const crossSize = 19.0,
      crossThickness = 1.0,
      crossOffset = 14.0,
      frameInset = 22.0,
      cornerMarkLength = 12.0,
      cornerMarkThickness = 1.0,
      railWidth = 2.5,
      glyphStroke = 1.6,
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

@immutable
class GravityTheme extends ThemeExtension<GravityTheme> {
  const GravityTheme({
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.textSecondary,
    required this.textMuted,
    required this.textGhost,
    required this.dotNeutral,
    required this.accent,
    required this.accentMuted,
    required this.accentSubtle,
    required this.textOnAccent,
    required this.rescue,
    required this.rescueSoft,
    required this.archive,
    required this.archiveSoft,
    required this.danger,
    required this.dangerSoft,
    required this.lineSubtle,
    required this.lineStrong,
    required this.cornerInk,
  });
  final Color bgTop,
      bgMid,
      bgBottom,
      surface,
      surfaceElevated,
      ink,
      textSecondary,
      textMuted,
      textGhost,
      dotNeutral,
      accent,
      accentMuted,
      accentSubtle,
      textOnAccent,
      rescue,
      rescueSoft,
      archive,
      archiveSoft,
      danger,
      dangerSoft,
      lineSubtle,
      lineStrong,
      cornerInk;
  static const light = GravityTheme(
    bgTop: GLight.bgTop,
    bgMid: GLight.bgMid,
    bgBottom: GLight.bgBottom,
    surface: GLight.surface,
    surfaceElevated: GLight.surfaceElevated,
    ink: GLight.ink,
    textSecondary: GLight.textSecondary,
    textMuted: GLight.textMuted,
    textGhost: GLight.textGhost,
    dotNeutral: GLight.dotNeutral,
    accent: GLight.accent,
    accentMuted: GLight.accentMuted,
    accentSubtle: GLight.accentSubtle,
    textOnAccent: GLight.textOnAccent,
    rescue: GLight.rescue,
    rescueSoft: GLight.rescueSoft,
    archive: GLight.archive,
    archiveSoft: GLight.archiveSoft,
    danger: GLight.danger,
    dangerSoft: GLight.dangerSoft,
    lineSubtle: GLight.lineSubtle,
    lineStrong: GLight.lineStrong,
    cornerInk: GLight.cornerInk,
  );
  static const dark = GravityTheme(
    bgTop: GDark.bgTop,
    bgMid: GDark.bgMid,
    bgBottom: GDark.bgBottom,
    surface: GDark.surface,
    surfaceElevated: GDark.surfaceElevated,
    ink: GDark.ink,
    textSecondary: GDark.textSecondary,
    textMuted: GDark.textMuted,
    textGhost: GDark.textGhost,
    dotNeutral: GDark.dotNeutral,
    accent: GDark.accent,
    accentMuted: GDark.accentMuted,
    accentSubtle: GDark.accentSubtle,
    textOnAccent: GDark.textOnAccent,
    rescue: GDark.rescue,
    rescueSoft: GDark.rescueSoft,
    archive: GDark.archive,
    archiveSoft: GDark.archiveSoft,
    danger: GDark.danger,
    dangerSoft: GDark.dangerSoft,
    lineSubtle: GDark.lineSubtle,
    lineStrong: GDark.lineStrong,
    cornerInk: GDark.cornerInk,
  );
  @override
  GravityTheme copyWith() => this;
  @override
  GravityTheme lerp(GravityTheme? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GravityTheme(
      bgTop: l(bgTop, other.bgTop),
      bgMid: l(bgMid, other.bgMid),
      bgBottom: l(bgBottom, other.bgBottom),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      ink: l(ink, other.ink),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textGhost: l(textGhost, other.textGhost),
      dotNeutral: l(dotNeutral, other.dotNeutral),
      accent: l(accent, other.accent),
      accentMuted: l(accentMuted, other.accentMuted),
      accentSubtle: l(accentSubtle, other.accentSubtle),
      textOnAccent: l(textOnAccent, other.textOnAccent),
      rescue: l(rescue, other.rescue),
      rescueSoft: l(rescueSoft, other.rescueSoft),
      archive: l(archive, other.archive),
      archiveSoft: l(archiveSoft, other.archiveSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      lineSubtle: l(lineSubtle, other.lineSubtle),
      lineStrong: l(lineStrong, other.lineStrong),
      cornerInk: l(cornerInk, other.cornerInk),
    );
  }
}
