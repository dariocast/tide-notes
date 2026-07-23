# Menu Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Tide's menu to expose a localized theme submenu, themed confirmation for deleting all notes, and native sharing of all notes as a timestamped `.tide` JSON file.

**Architecture:** Keep theme state in `AppearanceController`, add destructive storage behavior to `NoteRepository`/`LocalNoteRepository`, and keep export serialization in a focused presentation-independent utility. `TideBloc` owns delete/export commands and emits the existing user-message state; the settings widget only renders menu actions and invokes callbacks.

**Tech Stack:** Flutter Material, flutter_bloc, Drift, `share_plus`, JSON UTF-8 serialization, widget/bloc/repository tests.

---

### Task 1: Add storage and BLoC commands

**Files:**
- Modify: `lib/domain/repositories/note_repository.dart`
- Modify: `lib/data/repositories/local_note_repository.dart`
- Modify: `lib/presentation/blocs/tide_event.dart`
- Modify: `lib/presentation/blocs/tide_bloc.dart`
- Test: `test/presentation/blocs/tide_bloc_test.dart`

- [ ] Add `deleteAll()` to the repository contract and implement it with a Drift delete of every `noteRecords` row.
- [ ] Add `NotesDeleteAllRequested` and `NotesExportRequested` events; the export event carries the current `List<Note>` snapshot.
- [ ] Inject an export callback into `TideBloc`, catch delete/export failures, and emit localized user messages while preserving the notes stream.
- [ ] Extend the fake repository and bloc tests for successful delete dispatch and failure messaging.

### Task 2: Add `.tide` export serialization and sharing

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/core/utils/note_exporter.dart`
- Test: `test/core/utils/note_exporter_test.dart`

- [ ] Add `share_plus` and share an in-memory `XFile.fromData` through `SharePlus.instance.share(ShareParams(...))`, using `fileNameOverrides` for the `.tide` suffix.
- [ ] Serialize one JSON object per note with all six entity fields and ISO-8601 date strings.
- [ ] Generate names as `tide-YYYY-MM-DD_HH-mm.tide` using a supplied clock for deterministic tests.
- [ ] Test exact JSON shape, ordering, date encoding, filename, and empty-note export.

### Task 3: Refactor the settings menu UI

**Files:**
- Modify: `lib/presentation/widgets/tide_settings.dart`
- Modify: `lib/presentation/widgets/tide_header.dart`
- Modify: `lib/presentation/pages/tide_page.dart`
- Test: `test/presentation/pages/tide_page_test.dart`

- [ ] Replace the appearance-only control with a menu model exposing `Tema`, `Esporta note`, and `Elimina tutte le note`; keep adaptive bottom-sheet behavior on touch platforms and popup behavior on macOS.
- [ ] Make `Tema` open a second localized surface containing the existing theme choices and checks.
- [ ] Render delete as a destructive themed `AlertDialog` with cancel/confirm actions and no side effect on cancel.
- [ ] Wire menu callbacks to the BLoC, pass the current note snapshot for export, and verify menu labels/actions and dialog theming in widget tests.

### Task 4: Verify integration

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/data/repositories/local_note_repository_test.dart`

- [ ] Construct `TideBloc` with the repository delete operation and exporter callback in the production bootstrap.
- [ ] Test that `deleteAll()` removes all persisted records and the notes watcher emits an empty list.
- [ ] Run `dart format`, `flutter analyze`, and the complete `flutter test` suite.

