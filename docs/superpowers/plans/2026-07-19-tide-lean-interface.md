# Tide Lean Interface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the heavy card UI with Tide's compact, flat single-stream design and generate launcher icons from the supplied artwork.

**Architecture:** Presentation widgets remain Bloc-driven and domain/data boundaries do not change. New display formatting stays in pure core utilities; launcher icons are generated from one checked-in source with `flutter_launcher_icons`.

**Tech Stack:** Flutter 3.41.5, Material 3, flutter_bloc, flutter_test, flutter_launcher_icons 0.14.4.

---

## File map

```text
assets/icon/tide-app-icon.png                 source launcher artwork
lib/core/theme/tide_colors.dart               expanded accessible visual tokens
lib/core/theme/tide_theme.dart                typography/input/divider/snackbar themes
lib/core/utils/note_metadata_formatter.dart   deterministic relative time labels
lib/presentation/pages/tide_page.dart         centered max-width shell and clock injection
lib/presentation/widgets/tide_header.dart     title/count/date header
lib/presentation/widgets/note_composer.dart   compact outlined capture surface
lib/presentation/widgets/note_card.dart       flat note row, edit, metadata, rescue
lib/presentation/widgets/note_stream.dart     clock propagation and separators
lib/presentation/widgets/prefix_text.dart     prefix-only accessible styling
lib/presentation/widgets/tide_empty_state.dart compact stream message
test/                                         unit/widget regressions
pubspec.yaml                                  icon generator configuration
android/, ios/, macos/                        generated icon assets
```

## Task 1: Metadata formatter and visual tokens

- [x] Add failing tests in `test/core/utils/note_metadata_formatter_test.dart` for seconds/minutes/hours/days and rescue metadata.
- [x] Run `flutter test test/core/utils/note_metadata_formatter_test.dart`; verify RED because formatter is absent.
- [x] Implement pure functions `relativeSurfacedAge` and `rescueMetadata` in `lib/core/utils/note_metadata_formatter.dart`.
- [x] Expand `TideColors` and `TideTheme` with accessible canvas, divider, muted text, input, button, and snackbar styles using system typography.
- [x] Run formatter tests, `flutter analyze`, and existing theme/accessibility tests; verify GREEN.
- [x] Update these checkboxes and commit `feat: refine Tide visual foundation`.

## Task 2: Lean shell, header, composer, and empty state

- [x] Extend `test/presentation/pages/tide_page_test.dart` with failing assertions for one max-width column, `Tide`, note count/date, compact composer, and left-aligned empty copy.
- [x] Run page tests; verify RED on missing `TideHeader` and layout keys.
- [x] Add `TideHeader` with `noteCount` and injected `now`; localize date through `MaterialLocalizations`.
- [x] Center `TidePage` in a 760-pixel `ConstrainedBox`; keep header/composer fixed above `Expanded(NoteStream)`.
- [x] Restyle `NoteComposer` as a shallow outlined surface while preserving blank rejection, save semantics, focus retention, multiline Enter, and Meta+Enter.
- [x] Replace illustrated empty state with compact left-aligned text.
- [x] Run page, app, accessibility, and full widget tests; verify GREEN.
- [x] Update checkboxes and commit `feat: create Tide lean shell`.

## Task 3: Flat note rows and prefix-only color

- [ ] Extend `note_card_test.dart` and `prefix_text_test.dart` with failing assertions for no filled card decoration, metadata text, prefix-only color, separators, edit geometry, and rescue semantics.
- [ ] Run widget tests; verify RED on metadata/flat-row assertions.
- [ ] Refactor `PrefixText` to apply deterministic accessible color only to the parsed prefix and preserve body sinking color.
- [ ] Refactor `NoteCard` into a flat row with content, metadata, hairline separation, inline editor, restrained rescue background, and existing motion/haptic guards.
- [ ] Pass injected `now` through `TidePage` and `NoteStream`; keep stable keys and lazy builder behavior.
- [ ] Run parser/widget/page/rescue tests plus 10,000-note lazy test; verify GREEN.
- [ ] Update checkboxes and commit `feat: flatten Tide note stream`.

## Task 4: Launcher icon generation

- [ ] Copy the supplied 2000×2000 source to `assets/icon/tide-app-icon.png` and verify dimensions/alpha.
- [ ] Add `flutter_launcher_icons: ^0.14.4` under dev dependencies and configuration for Android, iOS, and macOS; set iOS alpha fill to `#F3F5F4`.
- [ ] Run `flutter pub get` and `dart run flutter_launcher_icons`.
- [ ] Verify generated Android mipmaps/adaptive XML, iOS AppIcon PNGs/manifest, macOS AppIcon PNGs/manifest, and absence of alpha in iOS output.
- [ ] Document icon regeneration command in README.
- [ ] Update checkboxes and commit `chore: apply Tide launcher icon`.

## Task 5: Complete MVP verification

- [ ] Run Drift code generation and strict format check.
- [ ] Run `flutter analyze`, `flutter test`, and macOS integration flow.
- [ ] Run Android debug APK, iOS simulator, and macOS debug builds.
- [ ] Inspect generated files, accessibility guidelines, spec compliance, `git diff --check`, unfinished-marker scan, and final status.
- [ ] Complete remaining checkboxes in the original MVP plan and this plan.
- [ ] Commit final verification/docs as `test: verify polished Tide MVP`.
