# Tide Lean Interface Design

**Date:** 2026-07-19  
**Status:** Approved by implementation directive  
**Scope:** Visual redesign and launcher icons only; MVP behavior remains unchanged

## Intent

Replace Tide's heavy card-based appearance with a calm, lean, single-stream interface. The interaction model remains Append, Review, Rescue. The visual treatment takes structural cues from Gravity's compact stream, Tot's single-window restraint, and Understory's progressive disclosure while retaining Tide's own powder/aqua/sand/ocean identity.

References:

- [Gravity](https://www.gravitynotes.app/): count/date header, linear composer, flat note stream, compact age/date/rescue metadata.
- [Tot](https://tot.rocks/): one-window focus, system-native typography, light/dark restraint.
- [Understory](https://understory.ussherpress.com/): editor-first UI with gestures and shortcuts revealed progressively.

Tide will not copy competitor branding, exact colors, assets, or feature scope.

## Layout

The screen is one centered column capped at 760 logical pixels on desktop and edge-to-edge on phones. Header and composer stay above the scrolling stream.

The compact header shows `Tide`, the note count, and current localized date. It has no navigation, settings, or decorative hero content.

The composer is a shallow surface with a subtle one-pixel outline, 16-pixel radius, multiline input, and one 44+ pixel save control. It keeps the existing visible save action and Command+Enter shortcut.

The stream uses flat rows separated by hairlines. Rows have no filled card background, drop shadow, or large rounded container. Note content leads; a small metadata line below shows relative surfaced age, calendar date, and rescue count when non-zero. Inline editing occupies the same row geometry.

The empty state is a short left-aligned message inside the stream rather than a centered illustration.

## Visual system

Light mode uses pearl canvas, ink text, powder/aqua accents, and sand warmth. Dark mode uses ocean canvas, moon text, desaturated blue-green accents, and no absolute black.

Typography uses platform fonts. Product title is 20/700; note content is 17/400 with 1.42 line height; metadata is 12/500. Sinking interpolates note body and metadata toward verified accessible muted colors while preserving at least 4.5:1 contrast.

Initial prefixes use deterministic accessible solid colors selected by the existing stable hash. This is the required fallback path from the MVP spec and avoids tinting the whole note body.

Motion remains 320 ms normally and 80 ms under reduced motion. Rescue uses a restrained aqua arrow/wave reveal. Haptic behavior remains mobile-only.

## App icon

The supplied 2000×2000 RGBA PNG becomes the checked-in source at `assets/icon/tide-app-icon.png`. `flutter_launcher_icons` 0.14.4 generates Android, iOS, and macOS icon sets.

iOS alpha is removed using Tide pearl (`#F3F5F4`) as the fill. Android receives both legacy and adaptive icons, with pearl adaptive background and the supplied artwork as foreground. macOS receives its complete AppIcon asset catalog.

## Architecture and behavior

Changes remain presentation/core-only plus generated platform assets. No repository, domain, database, or Bloc behavior changes. Time formatting is pure and deterministic; widgets receive an injectable clock where tests need stable output. State remains owned exclusively by `TideBloc`.

## Accessibility

All controls retain explicit semantic labels and 44/48 pixel targets. Note semantics expose full unchanged content once. Metadata is excluded from replacing note content semantics. Large text at 2× must not clip composer, header, note rows, or actions. Light/dark text must pass Flutter contrast checks.

## Acceptance criteria

- Flat centered stream; no heavy note cards.
- Header shows Tide, note count, localized date.
- Composer is compact and fixed above stream.
- Every note shows content plus age/date/rescue metadata.
- Append, edit, rescue, undo, reduced motion, semantics, and lazy construction continue passing.
- Supplied icon is generated for Android, iOS, and macOS.
- Format, analyze, unit/widget/integration tests, and all three platform builds pass.
