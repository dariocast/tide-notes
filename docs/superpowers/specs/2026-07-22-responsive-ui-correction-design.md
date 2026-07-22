# Tide Responsive UI Correction Design

**Date:** 2026-07-22  
**Status:** Approved  
**Scope:** Correct visual regressions, unify typography, differentiate macOS and mobile layouts, normalize display naming

## Intent

Restore Tide to a restrained, usable interface after the latest visual pass added decorative elements that conflict with the product. Preserve the Append, Review, Rescue interaction model and all existing data behavior.

## Removed Regressions

- Remove every editorial corner mark from the application shell.
- Remove the decorative Tide wave glyph from the header and empty state.
- Remove unused glyph and corner-frame implementation and tokens rather than leaving dead visual-system API.
- Keep the header product name as plain text.

## Typography

Use the platform system font for every text role on macOS, iOS, and Android. Retain a clear hierarchy through size, weight, line height, color, and spacing only. Remove the runtime use and asset declarations of Instrument Serif and Manrope when no remaining widget depends on them.

This replaces the current mixed serif/sans presentation and restores the platform-font direction from the approved lean-interface design.

## Adaptive Layout

Layout selection depends on both platform and available width:

- iOS and Android always use the mobile layout, including landscape and large mobile viewports.
- macOS uses the desktop split layout when available width is at least 840 logical pixels.
- macOS windows below 840 logical pixels fall back to the vertical layout so controls never clip.

### Mobile and Narrow macOS

Use one edge-to-edge vertical flow: header, composer, optional undo action, divider, then note stream. Horizontal padding follows the compact spacing tokens. Content remains optimized for touch and vertical scrolling.

### Wide macOS

Use a two-zone workspace inside a centered, wider shell:

- Left panel: fixed width between 300 and 340 logical pixels; contains header, note count/date, appearance control, composer, and optional undo action.
- Right panel: takes remaining width; contains the note stream or empty state.
- A subtle one-pixel vertical divider separates panels.
- Desktop pointer, focus, keyboard shortcut, and inline-edit behavior remain available.

The desktop shell may grow to roughly 1040 logical pixels. Note text remains constrained to a readable line length inside the stream.

## Header and Empty State

Header shows plain `Tide`, note count, localized date, and appearance settings. No icon or wordmark accompanies the name.

Empty state uses short left-aligned guidance only. It contains no logo, illustration, decorative mark, or desktop-only keyboard keycap. Guidance keeps the Append, Review, Rescue concepts understandable.

## Product Naming

User-visible application name is `Tide`, with uppercase `T`, everywhere:

- Flutter application title
- Android launcher label
- iOS display and bundle names
- macOS product and bundle name

Package names, bundle identifiers, database names, Dart import names, and other technical identifiers remain lowercase where required and are not migrated.

## Architecture

Keep business logic unchanged. Place adaptive-layout selection in presentation/design helpers behind a small, testable platform-and-width decision. Reuse the same header, composer, stream, and undo components across both layouts; only composition changes.

Remove obsolete decoration classes and tokens. Keep remaining colors, spacing, motion, and component themes centralized under `lib/design`.

## Accessibility and Behavior

- Preserve semantic labels, minimum target sizes, contrast, text scaling, keyboard traversal, reduced motion, and mobile-only haptics.
- Preserve append, edit, rescue, undo, lazy list construction, appearance persistence, and error handling.
- Wide and narrow layouts must avoid overflow at supported text scaling.

## Verification

Add or update widget/design tests covering:

- no decorative glyphs or corner frame in header and empty state;
- system-font typography across the full text theme;
- mobile vertical composition even at a wide mobile viewport;
- macOS two-zone composition at or above 840 logical pixels;
- macOS vertical fallback below 840 logical pixels;
- exact user-visible name `Tide` in platform configuration;
- existing interaction and accessibility tests remain green.

Run formatter, design-token lint, Flutter analyzer, full test suite, macOS build, and debug Android build. Preserve unrelated working-tree changes.

## Acceptance Criteria

- No corner marks or decorative Tide glyph appear anywhere in the app UI.
- No screen mixes unrelated font families; all UI text uses the platform system font.
- Mobile stays a compact vertical stream.
- Wide macOS presents controls left and notes right; narrow macOS degrades cleanly.
- All user-visible platform names use `Tide`.
- Existing product behavior and accessibility remain intact.
