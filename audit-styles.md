# Visual foundation audit

## Baseline

The pre-foundation application had a centralized light/dark theme with a warm,
square, editorially rigid treatment: default Material component shapes, a hard
accent rail on the composer and note rows, a manual reduced-motion preference,
and index-based sinking. Its shared widgets, in priority order, were `NoteCard`,
`NoteComposer`, `NoteStream`, `TideHeader`, `PrefixText`, and `TideEmptyState`.

Golden infrastructure is not present in this small native-only project; the
existing widget suite is retained and trimmed to high-value design-contract and
accessibility coverage. Screenshot golden capture remains a release-pipeline
addition.

## Atlantic foundation map

| Concern | Atlantic foundation |
| --- | --- |
| Theme palettes | `TideColors.foam` (light), `TideColors.deepTide` (dark), `TideColors.abyss` (true-black OLED) |
| Theme selection | `TideThemeSelection` (System, Foam, Deep Tide, Abyss); persisted and mapped in `TideApp` |
| Typography | Quicksand (app name, section/empty-state titles) + Nunito (note content, prefixes, metadata, controls), bundled locally under OFL 1.1 with declared platform fallbacks |
| Composer | Shallow rounded surface (`GShapes.composer`), calm border, circular append action, no hard rail or heavy shadow |
| Note stream | Flat rows, no card shell / left rail / drop shadow; low-contrast bottom hairline; soft water-wash hover; restrained focus outline |
| Depth | Viewport-relative sinking via `TideDepthFade`: full presence through the top 65%, bottom-only alpha gradient to a theme-specific floor; recovers as notes rise; bypassed while editing and in high-contrast mode |
| Motion | OS-driven `TideMotionPolicy`; OS reduced motion yields zero-duration non-essential transitions; the manual motion preference is removed |
| Empty state | Text only: one Quicksand title and one Nunito guidance line, left aligned |

## Current audit

`tool/design_token_lint.sh` reports zero forbidden visual literals outside
`lib/design`. The only excluded `Duration` is the BLoC edit debounce, which is
business timing rather than visual motion. All palette, typography, layout,
shape, and fade values now originate under `lib/design`.

Contrast is enforced rather than judged: pure tests calculate worst-case
composited contrast for resting, hovered, and deepest-viewport-fade states
across Foam, Deep Tide, and Abyss, and each theme's fade floor is derived from
the 4.5:1 contract rather than chosen arbitrarily.

## Remaining scope

Search is intentionally excluded from this visual foundation. It will receive a
separate design and implementation cycle after the foundation is complete; the
compact header reserves a balanced right slot as a layout spacer for that later
search action. Platform screenshot goldens (Foam/Deep Tide/Abyss × compact/
expanded) remain a future CI addition.
