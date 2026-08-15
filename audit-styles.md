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
composited contrast for the hovered state (Foam, Deep Tide) and the
deepest-viewport-fade state (Foam, Deep Tide, Abyss); resting-state contrast
is enforced via widget-level accessibility-guideline checks (Foam, Deep Tide).
Each theme's fade floor is derived from the 4.5:1 contract rather than chosen
arbitrarily. Abyss hover and resting contrast are not yet independently
pure-tested — a follow-up gap noted for a future pass.

## Interaction parity additions

A follow-on effort ported a rival notes app's interaction model onto the
Atlantic foundation above. In every case only interaction structure and
information architecture were adopted; no color, typography, icon asset, or
illustration was reused from that rival app. The additions:

- **Archive/trash lifecycle.** `NoteRepository` gained `archive` /
  `restoreFromArchive`, `softDelete` / `restoreFromTrash`, and
  `permanentlyDelete` / `emptyTrash`. `ArchivePage` and `DeletedNotesPage`
  list these notes using the existing `NoteCard` and empty-state widgets, so
  they inherit the Atlantic flat-row treatment rather than introducing a new
  list style.
- **Swipe-left action panel.** `NoteCard` wraps its row in a `Slidable`
  (`flutter_slidable`) whose start action pane preserves the prior
  `DismissiblePane` swipe-right rescue gesture (matching `Dismissible`'s
  0.4 dismiss threshold), while a new end action pane reveals Archive,
  Delete, Share, and Copy as `SlidableAction`s. Their colors are drawn from
  `tideColorsOf` (`g.textMuted`, `g.danger`/`g.dangerSoft`, `g.accent`,
  `g.accentMuted`/`g.accentSubtle`) and their icons from `TideIcons` — no new
  palette or icon set.
- **Long-press full-screen editing.** Long-pressing a note row now pushes
  `NoteEditPage`, a `MaterialPageRoute` reusing the same theme, typography,
  and markdown preview as inline editing, for a distraction-free full-screen
  edit rather than a new visual language.
- **Tide Stats.** `TideStatsPage` computes counts (total notes, notes/day,
  average rescues, rescues/day) via `NoteStats.compute` and lays them out in
  a `GridView` of stat cards using `GSpace` and `tideColorsOf` tokens — no
  bespoke chart or illustration styling.
- **Tutorial screen.** `TideTutorialPage` is a static, self-contained
  walkthrough built from in-memory demo `Note`s created in `initState`; it
  never reads the `TideBloc` or repository, so swiping, long-pressing, or
  editing a demo note cannot touch real data. It renders through the same
  `NoteCard` used everywhere else.
- **Sectioned settings menu.** `TideSettingsButton`'s bottom sheet (mobile)
  and popover (macOS) are now organized under `_SectionHeader`s — Content,
  Data, Editor, Appearance, Search — rather than a flat action list, to
  accommodate the growing set of destinations (Archive, Deleted Notes,
  Stats, Tutorial) without becoming a wall of undifferentiated items.
- **Search results count and inline highlight.** The search header reports a
  localized results count (`searchResultsCount`), and the active query is
  threaded as `highlightQuery` through `NoteStream` → `NoteCard` →
  `PrefixText`, which highlights matching text within a note's first line
  using the existing accent token rather than a new highlight color.
- **Markdown rendering.** Note bodies (everything after the first line,
  per `markdownBodyFor`) render through `flutter_markdown_plus`.
  `tideMarkdownStyleSheet` maps the existing `TextTheme` and `tideColorsOf`
  palette onto `MarkdownStyleSheet`, and code/quote block shapes come from
  `GShapes`, so a theme switch restyles rendered markdown automatically
  without a second set of colors or fonts to maintain.

`tool/design_token_lint.sh` continues to report zero forbidden visual
literals outside `lib/design` after these additions; the panel, stats, and
markdown styling above route through the same token set audited in
"Current audit" rather than introducing parallel literals.

## Remaining scope

Search's results-count and inline-highlight behavior, previously called out
here as excluded, has since been implemented (see "Interaction parity
additions" above); the compact header's balanced right slot now hosts that
search action rather than reserving space for it. Platform screenshot
goldens (Foam/Deep Tide/Abyss × compact/expanded) remain a future CI
addition.
