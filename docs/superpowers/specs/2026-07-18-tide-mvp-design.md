# Tide MVP Design

**Date:** 2026-07-18  
**Status:** Approved for planning  
**Platforms:** iOS, Android, macOS  
**Framework:** Flutter

## Product intent

Tide is a single-stream notes app built around three moves:

1. **Append:** capture any plain-text thought at the top without categorization.
2. **Review:** scan the stream from newest to oldest while older thoughts sink.
3. **Rescue:** swipe right on a relevant thought to lift it back to the top.

The product treats forgetting as useful curation. It deliberately excludes folders, persistent tags, and hierarchy. This direction follows the append-review-rescue method described in [Why Your Notes App Is Backwards](https://www.gravitynotes.app/blog/why-gravity-exists), while Tide uses its own identity and interaction design.

## MVP scope

The MVP is local-first and works fully offline. It includes:

- one continuous note stream;
- fixed capture composer;
- plain-text multiline notes;
- inline editing with automatic persistence;
- right-swipe rescue;
- undo for accidental rescue;
- position-based visual sinking;
- automatic visual treatment for an initial prefix;
- system light and dark themes;
- iOS, Android, and macOS targets.

The MVP excludes cloud sync, accounts, folders, stored tags, filters, search, attachments, Markdown, archive, deletion, analytics, multi-page onboarding, and complex settings. Repository boundaries must permit later sync without requiring presentation or domain rewrites.

## Architecture

Use Clean Architecture with a layer-first structure:

```text
lib/
  core/          errors, theme, utilities, shared widgets
  data/          local data sources, models, repository implementations
  domain/        entities, repository interfaces, use cases
  presentation/  blocs, pages, widgets
  main.dart
```

Dependencies point inward. Domain is pure Dart and never imports Flutter or data classes. Presentation uses domain abstractions and never accesses data sources. Data maps persistence models to domain entities.

`flutter_bloc` is the only state management solution. Business and async state lives in Bloc/Cubit. `setState` is allowed only for isolated ephemeral UI state. Dependencies use constructor injection, `RepositoryProvider`, and `BlocProvider`; no service locator or DI framework is allowed. Navigation, snackbar, and other UI side effects use `BlocListener`.

### Main flow

```text
Widgets -> TideBloc -> use cases -> NoteRepository interface
                                      ^
                                      |
                         LocalNoteRepository -> Drift/SQLite
```

The local repository exposes a reactive note stream. A future sync-aware repository may coordinate local and remote data behind the same domain interface.

## Domain model

`Note` contains:

- `id`: locally generated UUID;
- `content`: plain-text note body;
- `createdAt`: initial creation time;
- `updatedAt`: last content edit time;
- `surfacedAt`: creation or most recent rescue time;
- `rescueCount`: number of completed rescues.

Display order is `surfacedAt DESC`, with deterministic `id` ordering for ties. Editing updates `updatedAt` but never changes stream position. Rescue updates `surfacedAt` and increments `rescueCount` atomically.

Required use cases:

- `WatchNotes`
- `AppendNote`
- `EditNote`
- `RescueNote`
- `UndoRescue`

Undo restores the immediately preceding `surfacedAt` and `rescueCount` for the rescued note. Only the latest pending rescue action needs to be undoable.

## Persistence

Use Drift over SQLite with versioned schema migrations. All operations work without network access. Note mutations are transactional where multiple fields change together.

Input rules:

- content containing only whitespace is not saved;
- trailing whitespace is removed before persistence;
- internal whitespace and line breaks are preserved;
- automatic prefix styling never modifies stored content.

Persistence errors leave the last valid state visible. Tide shows concise, user-facing feedback and offers retry when the failed action is retryable. Raw exceptions and technical messages never reach users.

## Experience

### Single screen

The app opens directly to one screen:

- fixed composer at the top;
- lazy, reactive stream below;
- compact empty state explaining Append, Review, Rescue.

The composer is multiline. A visible save button submits on every platform. `Command+Enter` submits on macOS. After successful append, the composer clears and retains focus where platform conventions allow.

### Editing

Tapping a note activates inline editing. Changes autosave after a short debounce and flush when focus leaves the editor. Edit persistence does not move the note. Async editing state and failures are coordinated by `TideBloc`; focus and local animation state may remain ephemeral widget state.

### Rescue

Swiping a note right beyond an explicit threshold rescues it. Horizontal movement avoids conflict with vertical stream scrolling. The note animates upward with a soft wave-like motion. Supported mobile devices emit light haptic feedback; macOS omits haptics. A snackbar offers Undo. The first note cannot be rescued again while already at the top.

Reduced-motion platform preferences replace the wave with a short fade/reorder transition.

### Visual sinking

Sinking is based on visible stream position, not wall-clock age. Text emphasis decreases gradually as rows move down, but every rendered state must retain at least 4.5:1 contrast against its background. The effect may adjust foreground tone and card treatment; it must not reduce whole-card opacity enough to expose distracting content underneath.

The list uses lazy construction and stable keys so large streams do not render eagerly.

### Automatic prefix styling

If content starts with a token matching this conceptual form, Tide styles that token through its colon:

```text
^[Unicode letter or number, underscore, or hyphen]+:
```

Examples: `todo:`, `idea:`, `read:`. Only the first token at the beginning of the note qualifies. Matching is case-insensitive for color selection. A deterministic hash maps normalized prefix text to an accessible gradient palette. The prefix is neither extracted nor stored as metadata and creates no tag/filter behavior.

When gradient text cannot maintain required contrast, rendering falls back to a single accessible palette color. Screen readers receive the unchanged full note text.

### Theme

Light mode uses desaturated powder blue, aqua, pearl gray, and sand. Dark mode uses deep ocean blue rather than absolute black. Theme follows system mode; no manual toggle is required in MVP.

All controls expose semantic labels. Layout supports system text scaling without clipping or hiding actions. Interaction targets follow platform accessibility sizing.

## State and error handling

`TideBloc` is the single source of truth for stream and mutation state. It subscribes to `WatchNotes`, dispatches append/edit/rescue/undo use cases, and emits:

- initial/loading state;
- loaded state containing immutable notes and per-action progress;
- recoverable user-facing failure state/effect;
- terminal initialization failure with retry.

Rapid edits for one note are serialized or superseded so stale debounce completions cannot overwrite newer text. Repeated rescue input for a note is ignored while its rescue is in flight. Stream subscription errors preserve the last loaded notes when possible.

## Testing

### Unit tests

- domain behavior for append, edit, rescue, undo, validation, and ordering;
- data model/entity mapping;
- repository transactions and schema migration;
- Bloc loading, success, failure, edit concurrency, and rescue deduplication.

### Widget tests

- composer submission and empty-content rejection;
- inline edit and focus-loss flush;
- prefix detection and accessible fallback;
- swipe threshold, rescue feedback, and undo;
- position-based sinking;
- light/dark rendering, large text, and semantics.

### Integration tests

Run append -> edit -> rescue -> app restart and verify content, order, timestamps, and rescue count persist.

## Completion criteria

- iOS, Android, and macOS builds succeed in the available local toolchain.
- App opens directly to composer and stream.
- Saved notes survive restart.
- Rescue immediately moves a note to the top and Undo restores prior order.
- With 10,000 seeded notes, an automated widget test verifies that fewer than 100 note rows are mounted at once; a profile-mode smoke test scrolls continuously for 30 seconds without visible stalls or crashes.
- Light/dark modes follow system settings.
- All readable text maintains at least 4.5:1 contrast.
- Core controls have semantic labels and remain usable with increased system text size.
- Static analysis, unit tests, widget tests, and integration test pass.
- No network access is required.

Signing, store metadata, distribution, production telemetry, and cloud infrastructure are release work outside this MVP.
