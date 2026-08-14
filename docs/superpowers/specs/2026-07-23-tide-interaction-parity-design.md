# Tide Interaction Parity Design

**Date:** 2026-07-23
**Status:** Approved in design review
**Scope:** Port Gravity's interaction model (gestures, editing, archive/trash, stats, tutorial, settings structure, markdown rendering) onto Tide's existing Atlantic visual foundation. No color, typography, or naming is borrowed from Gravity — only structure, gestures, and information architecture.

## Intent

A competitive study of Gravity (conducted via `adb` against a real device install, screenshots retained under the working session, no APK extraction or decompilation) surfaced a mature interaction model: a reveal-based swipe action panel, a dedicated full-screen edit surface reached by long-press, an archive/trash lifecycle for notes, a local stats dashboard, an interactive in-app tutorial, a richer sectioned settings menu, and light markdown rendering of note content.

Tide already implements several of these ideas on its own terms — rescue/bump via right-swipe, undo receipts, live search, import/export, theme and language selection. This design closes the remaining gap: everything that is pure interaction, information architecture, or structure is aligned to Gravity's model; every color, font, icon glyph, and piece of copy stays Tide's own (Atlantic palettes, Quicksand/Nunito, the existing `TideIcons` Font Awesome vocabulary, Tide's voice).

## Scope Boundaries

Included:

- swipe-left reveal panel (Archive / Delete / Share / Copy) alongside the existing swipe-right rescue;
- a dedicated full-screen edit page reached by long-press, additive to the existing inline edit;
- a paste-from-clipboard action on the composer;
- Archive and Deleted Notes (trash) screens, with matching domain/persistence support;
- a local, on-device "Tide Stats" screen;
- an interactive in-app tutorial reachable from Settings;
- a sectioned settings menu (Content / Data / Editor / Appearance / Search);
- a results count and inline term highlight added to the existing search feature;
- read-only markdown rendering of note content in the stream, expanded view, and full-screen edit preview.

Excluded (explicitly deferred, not part of this cycle):

- WYSIWYG / rich-text editing — the composer and edit surfaces remain plain-text input; only *display* renders markdown;
- folder-based automatic backups and database maintenance/compaction tooling;
- an in-app text-size override (Tide already honors the OS accessibility text scale);
- an app-store review prompt;
- any change to Tide's palettes, typography, or icon *style* — only which icon roles exist is extended, using the same Font Awesome set already in use.

## Competitive Reference

Screens studied on-device: home stream (light/dark), settings (all sections), theme/text-size pickers, note expansion, search with live results and inline highlighting, swipe-left action panel, Archive, Deleted Notes with confirm dialog, Stats for Nerds, the interactive "How to use Gravity" tutorial, and the long-press full-screen Edit surface. Gravity's own branding, illustrations (its feather glyph), exact color values, and copy are not reused anywhere in this design.

## Markdown Rendering

Notes are typed and edited as plain text, exactly as today. `Note.content` remains a plain `String` in the domain and in Drift — **no schema change** and no change to import/export JSON, which continue to carry raw content.

Display surfaces (stream rows, the existing inline-expanded view, and the new full-screen edit page's preview) render that string with `flutter_markdown_plus` (`MarkdownBody`), the actively maintained continuation of Flutter's own now-discontinued `flutter_markdown` package, built on the actively maintained `markdown` parser. A single `MarkdownStyleSheet` factory in `lib/design` maps heading/body/code/quote/list styles onto Tide's existing `TextTheme` and `TideColors` (Quicksand headings, Nunito body, `accentSubtle` inline-code background, `lineSubtle` blockquote rule) — the same tokens every other component already uses, so a theme switch restyles rendered markdown automatically. Supported syntax mirrors what Gravity demonstrated: `#`/`##` headings, `**bold**`/`*italic*`, `` `inline code` ``, `>` quotes, and bullet/numbered/lettered lists.

The plain-text composer and both edit surfaces are unaffected: editing is still a `TextField` over the raw markdown string. Search continues to match against the raw string as today.

## Data Model and Persistence

`Note` gains two nullable fields, both defaulting to unset for existing rows:

```dart
final DateTime? archivedAt;
final DateTime? deletedAt;
```

`archivedAt == null && deletedAt == null` means visible in the main stream — the only condition `watchNotes()` already needs to add to its query. Two additional repository streams back the new screens:

```dart
Stream<List<Note>> watchArchivedNotes(); // archivedAt != null && deletedAt == null
Stream<List<Note>> watchDeletedNotes();  // deletedAt != null
```

Drift: two new nullable `DateTime` columns on the notes table, one schema version bump, one migration step (`ALTER TABLE ... ADD COLUMN`, both nullable — no backfill needed).

New domain surface, following the existing `RescueNote`/`RescueReceipt`/`UndoRescue` shape so Archive and Delete get the same one-shot undo affordance the stream already gives Rescue:

```dart
ArchiveNote        // sets archivedAt; returns an ArchiveReceipt for undo
RestoreFromArchive // clears archivedAt (moves back to the main stream)
DeleteNote         // sets deletedAt (soft delete); returns a DeleteReceipt for undo
RestoreFromTrash   // clears deletedAt
PermanentlyDeleteNote
EmptyTrash         // permanently deletes every row with deletedAt != null
```

`NotesDeleteAllRequested` (the existing "Delete All" in Settings) is unchanged: it remains an instant, permanent wipe of every note regardless of archive/trash state, with its existing confirmation dialog. It is a deliberately different, simpler guarantee than the new per-note soft-delete flow, and Settings keeps both actions distinct.

`Note.copyWith` gains `archivedAt`/`deletedAt` parameters; `NoteExporter`'s JSON also serializes both fields so exported/imported archives round-trip correctly.

## Gestures and Editing

**Swipe-right** (any note, any of the three lists) is unchanged: the existing `Dismissible(DismissDirection.startToEnd)` triggers rescue in the main stream. On the Archive screen the same right-swipe triggers `RestoreFromArchive`; on Deleted Notes it triggers `RestoreFromTrash`. Same visual treatment (`rescueSoft` background, `TideIcons.surface`), same haptic, same semantics pattern already established by `NoteCard`.

**Swipe-left** reveals a persistent action row instead of completing a dismiss — this needs a reveal-and-hold gesture, not a complete-and-snap-back one, so we add `flutter_slidable` (a focused, actively maintained package built exactly for this pattern) rather than hand-rolling drag physics on top of `Dismissible`. Panel actions and colors, using Tide's own semantic tokens rather than Gravity's literal hues:

| Screen | Actions revealed on swipe-left |
| --- | --- |
| Main stream | Archive (`textMuted` tint), Delete (`danger`), Share (`accent`), Copy (`accentMuted`) |
| Archive | Delete (`danger`), Share (`accent`), Copy (`accentMuted`) — Archive is not offered on an already-archived note |
| Deleted Notes | Delete permanently (`danger`) only — matches Gravity's trash-screen behavior where left-swipe is the permanent action |

Share reuses the existing `share_plus` dependency (already wired for bulk export) with a single note's plain content instead of a JSON file. Copy writes the note's content to the system clipboard via `Clipboard.setData`. Archive and Delete (soft) show the same brief undo snackbar pattern Rescue already uses.

**Long-press** on a note (main stream, Archive, or Deleted Notes) opens `NoteEditPage`, a new full-screen route: a close (`X`) action and a confirm (check) action in the header, a plain-text field seeded with the note's raw content, and a live markdown preview below it using the same `MarkdownStyleSheet`. Confirming dispatches the existing `NoteEditRequested` event; closing discards changes. This is **additive** — tapping a note still opens Tide's existing inline edit-in-place behavior, unchanged.

**Composer**: a new leading trailing-icon (before the existing submit icon) reads the system clipboard via `Clipboard.getData('text/plain')` and inserts it at the cursor position, mirroring Gravity's paste action. No behavior change to the existing submit icon, Command+Enter, or the `submitOnEnter` quick-submit setting.

## New Screens

**Archive** (`ArchivePage`): backed by `watchArchivedNotes()`. Empty state is text (Tide's established empty-state voice) plus one small line-art icon in Tide's own water motif (not Gravity's feather) at low opacity in `textMuted`/`lineSubtle` tone — the icon is illustrative, not branded, and themes with the rest of the app.

**Deleted Notes** (`DeletedNotesPage`): backed by `watchDeletedNotes()`. Same empty-state treatment as Archive. A top "Delete All Permanently" action opens a confirmation dialog (irreversible, matching the existing `deleteAllTitle`/`deleteAllBody` dialog pattern already used for Settings' Delete All) and calls `EmptyTrash`.

**Tide Stats** (`TideStatsPage`): computed client-side from the notes already available through `watchNotes()` combined with `watchArchivedNotes()` (active + archived notes; trashed notes are excluded — they're on their way out). No new queries or aggregation infrastructure. Sections:

- quick stats: total notes, notes per day (since first note), average rescues, rescues per day;
- details: longest note (words/characters), most-rescued note (rescue count), first note's date, total characters across all included notes;
- a word-count distribution bar chart (same four-bucket trimmed-percentile shape observed in Gravity), rendered with existing Tide chart primitives if any exist, otherwise simple `Container`-based bars using `TideColors.accent`/`accentMuted`;
- a "computed locally" footnote, matching Tide's local-first positioning.

No review-prompt CTA.

**Tutorial** (`TideTutorialPage`): reachable only from Settings under the entry "How Tide Works." Shows two or three self-contained demo note rows, backed by static in-memory data (never the user's real notes or repository), that the user can actually swipe (right = rescue, left = reveal the action panel) and long-press (opens `NoteEditPage` against the same demo data) to learn the gestures hands-on, mirroring Gravity's interactive approach. Never shown automatically; first-launch behavior is unchanged.

## Settings Reorganization

`TideSettingsButton`'s sheet (mobile) and popover (macOS) are restructured into named sections, keeping every existing entry point and adding the new ones:

- **Content**: Archive, Deleted Notes, Tide Stats, How Tide Works (tutorial)
- **Data**: Import Notes, Export Notes (relocated, unchanged behavior)
- **Editor**: the existing quick-submit ("double return to save"-equivalent) toggle
- **Appearance**: Theme selection and Language selection (relocated, unchanged behavior)
- **Search**: new "Include archived notes in search" toggle, default on
- Delete All stays visually separate and destructive at the end, as today

Both the mobile bottom sheet and the macOS `PopupMenuButton` get the same section structure (section headers in the sheet, dividers plus grayed-out section labels in the popover, consistent with the popover's existing divider usage).

## Search Polish

No architectural change to the search feature described in `2026-07-24-note-search-design.md` — it remains presentation-only, header-replacement, live substring filtering, no BLoC involvement. Two additions layered on top:

- a localized results-count line ("N notes found" / zero shown as the existing no-results state, unchanged) rendered above the list while searching;
- inline highlighting of the matched substring within each visible note's content, rendered as a background-tinted `TextSpan` using `TideColors.accentSubtle` (not Gravity's tan), computed the same case-insensitive way the existing filter already matches.

Both are pure presentation derived from the existing `_searchController.text` and the already-filtered note list — no new state in `TidePage` beyond what search already tracks.

## Icon Vocabulary

`TideIcons` gains new roles from the Font Awesome set already bundled, keeping the existing "water first, generic second" convention where a natural fit exists:

```dart
static const paste = FontAwesomeIcons.paste;
static const archive = FontAwesomeIcons.boxArchive;
static const share = FontAwesomeIcons.shareNodes;
static const copy = FontAwesomeIcons.copy;
static const stats = FontAwesomeIcons.chartSimple;
static const tutorial = FontAwesomeIcons.circleQuestion;
```

`restore` reuses the existing `TideIcons.surface` (already means "bring back up") for both archive-restore and trash-restore — no new glyph needed.

## Localization

All new copy (Archive/Deleted Notes screen titles and empty states, Stats labels, tutorial copy, new settings section headers and entries, results-count string, Share/Copy/Archive/Delete-permanently action labels and semantics) is added to both English and Italian in `lib/l10n`, following the existing key-per-string convention.

## Architecture Summary

- `lib/domain/entities/note.dart`: add `archivedAt`/`deletedAt`.
- `lib/domain/repositories/note_repository.dart` + Drift implementation: new streams and mutation methods, one migration.
- `lib/domain/usecases/`: six new usecases (`archive_note.dart`, `restore_from_archive.dart`, `delete_note.dart`, `restore_from_trash.dart`, `permanently_delete_note.dart`, `empty_trash.dart`), mirroring the existing `rescue_note.dart`/`undo_rescue.dart` pair style.
- `lib/presentation/blocs/`: new events/state fields for archive/delete/restore + their undo receipts, following the existing `NoteRescueRequested`/`RescueUndoRequested` pattern.
- `lib/design/`: new `MarkdownStyleSheet` factory; `TideIcons` additions.
- `lib/presentation/widgets/note_card.dart`: swipe-left `Slidable` action panel; long-press opens `NoteEditPage`; markdown-rendered content.
- `lib/presentation/widgets/note_composer.dart`: paste icon.
- `lib/presentation/pages/`: new `ArchivePage`, `DeletedNotesPage`, `TideStatsPage`, `TideTutorialPage`, `NoteEditPage`.
- `lib/presentation/widgets/tide_settings.dart`: sectioned restructuring, new entries wired to the new pages.
- `lib/presentation/widgets/tide_search_header.dart` / search rendering path: results count + inline highlight.
- `lib/core/utils/note_exporter.dart`: serialize new fields; add single-note share helper.
- `pubspec.yaml`: add `flutter_slidable` and `flutter_markdown_plus`.

Domain and BLoC changes are additive (new fields default to `null`, new events/usecases are new files); no existing usecase, event, or repository method signature changes.

## Testing Strategy

Following Tide's established lean-but-load-bearing test posture:

- domain: usecase tests for each new archive/delete/restore/permanent-delete usecase and its receipt/undo round-trip; repository tests for the three watch streams' filtering; a Drift migration test for the new columns.
- BLoC: new event-to-state coverage for archive/delete/restore flows and their undo snackbars, mirroring existing rescue tests.
- widget: swipe-left panel reveals the correct action set per screen (main stream vs. Archive vs. Deleted Notes) and dispatches the right action; long-press opens `NoteEditPage` and both confirm/discard paths; composer paste icon inserts clipboard content; Archive and Deleted Notes screens' empty/populated states and their swipe-right restore; Stats page's pure computation functions (one parameterized test covering the aggregation math, not a widget-heavy suite); tutorial demo rows respond to gestures without touching the real repository; search results-count and inline-highlight rendering; markdown style sheet resolves the right token per theme (Foam/Deep Tide/Abyss).
- Run `dart format`, `tool/design_token_lint.sh`, `flutter analyze`, and the full `flutter test` suite after implementation, plus `flutter build macos` and `flutter build apk --debug`.

## Acceptance Criteria

- Swipe-right still rescues/restores exactly as today on every list; swipe-left reveals the correct action set per screen and every action works, with undo available for Archive and Delete.
- Long-press opens a full-screen edit page on any note in any of the three lists; tap-to-inline-edit is unchanged.
- The composer's paste icon inserts clipboard content; existing submit behavior is unchanged.
- Archive and Deleted Notes screens exist, are reachable from Settings, and correctly reflect `archivedAt`/`deletedAt`; Deleted Notes offers per-note permanent delete and an "empty trash" action with confirmation.
- Settings' existing "Delete All" is unchanged (instant, permanent, bypasses trash).
- Tide Stats shows accurate, locally computed figures with no network/review-prompt content.
- The tutorial is reachable only from Settings, never shown automatically, and its gestures never touch real note data.
- Settings is reorganized into the five named sections with every existing entry still present and functional.
- Search shows a results count and highlights the matched term inline; its existing behavior (case-insensitive substring, live filtering, no BLoC involvement) is unchanged.
- Markdown syntax in note content renders styled in the stream, expanded view, and edit-page preview, using only Tide's existing palette and typography tokens; the stored content and editing surfaces remain plain text.
- No Gravity branding, color values, icon assets, or illustration (the feather) appear anywhere in Tide.
- Existing note behavior (append, inline edit, rescue, undo, search, import, export, theme/language selection, delete all) and accessibility contracts remain green.
