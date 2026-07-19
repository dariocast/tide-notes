# Design-system v2 migration audit

## Fase 0 baseline

The pre-migration application had a centralized light/dark `TideTheme`, but
used a cool ocean palette, default Material component treatments, literal
spacing and local typography overrides. Its shared widgets, in priority order,
were `NoteCard`, `NoteComposer`, `NoteStream`, `TideHeader`, `PrefixText`, and
`TideEmptyState`.

Golden infrastructure is not present in this small native-only project; the
existing widget suite is retained and extended with design-contract and
accessibility coverage. Screenshot golden capture remains a release-pipeline
addition.

## Conversion map

| Legacy pattern | Gravity v2 mapping |
| --- | --- |
| Cool `TideColors` palette | `GravityTheme` warm light/dark pairs |
| `ColorScheme.fromSeed` defaults | explicit `ColorScheme` plus theme extension |
| 760px shell | `GLayout.contentMax` (720) |
| 24/16/8 spacing literals | `GSpace.s5/s4/s2` |
| 16px composer radius | `RoundedRectangleBorder()` / zero radius |
| local animation durations | `GMotion` through `context.motion` |
| `MediaQuery` layout decisions | centralized `sizeClassOf(context)` |
| rescue snackbar | inline undo action; successful rescue has no toast |

## Current audit

`tool/design_token_lint.sh` reports zero forbidden visual literals outside
`lib/design`. The only excluded `Duration` is the BLoC edit debounce, which is
business timing rather than visual motion. All palette, typography, layout,
shadow and motion values now originate under `lib/design`.

## Design-lead validation queue

- Validate the derived dark palette and pressed treatment on device (§3, §6.3).
- Add platform screenshot goldens (light/dark × compact/expanded) to CI (§12.2).
- Validate bump-flash/reordering animation after the stream adopts an
  animated-list implementation (§7.3).
