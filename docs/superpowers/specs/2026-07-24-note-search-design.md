# Tide Note Search Design

**Date:** 2026-07-24  
**Status:** Approved  
**Scope:** Add live, presentation-layer search to the note stream

## Intent

Let users find notes immediately from Tide's primary screen without submitting
a form or leaving the stream. Search is temporary UI state: it does not change
stored notes, their order, or the existing Append, Review, Rescue model.

## Interaction

In the normal state, the header keeps the settings control, title, note count,
and date. A Font Awesome magnifying-glass action appears at the far right.

Selecting the action replaces the complete header contents with:

- a focused search field;
- a trailing Font Awesome `xmark` action when the field is not empty;
- a localized `Cancella`/`Cancel` text action to the right of the field.

The composer collapses while search is active but remains mounted so an
existing draft is preserved. The search field receives focus immediately.

Results update after every text change; no submit action is required. The
trailing `xmark` clears the text while keeping search mode, keyboard focus, and
the search field open. The text action clears the query, closes search, and
restores the regular header and composer. Reopening search always starts with
an empty field.

An empty query shows the complete stream. A non-empty query with no matches
shows a dedicated localized no-results message rather than the normal
empty-stream guidance.

## Matching Rules

Search compares the query with `Note.content`, which includes any textual
prefix stored as part of the note. Matching is:

- case-insensitive;
- based on a contiguous substring;
- performed against the full note content;
- order-preserving, using the current order supplied by `TideState.notes`.

Leading and trailing whitespace in the query is ignored. Internal whitespace
and diacritics remain significant. Search does not inspect timestamps, rescue
counts, or formatted metadata.

## Layout and Motion

The search field replaces the header region in both compact vertical layouts
and the wide macOS sidebar. The search controls respect the existing horizontal
spacing and minimum touch-target tokens.

When the on-screen keyboard leaves a compact viewport, the search header stays
visible even where `TideShell` would normally omit the regular header. Because
the composer is collapsed, the results retain the remaining viewport.

Header replacement uses a restrained fade/size transition. Composer collapse
and restoration use a size transition that preserves the composer's state.
Durations use centralized motion tokens and become zero when the operating
system requests reduced motion.

## Architecture

`TidePage` owns the ephemeral search mode, query, text controller, and focus
node. It derives the visible note list synchronously from each current
`TideState.notes` snapshot and passes that list to `NoteStream`.

`TideHeader` adds the search action. A focused search-header widget owns only
the visual controls and delegates text changes, clearing, and closing through
callbacks. Search and clear icons are added to the shared `TideIcons`
vocabulary and rendered through Font Awesome like the application's other
icons.

`TideShell` accepts enough presentation state to keep the search header visible
in compact-height layouts and to collapse the mounted composer safely.
`NoteStream` distinguishes a search with no matches from an actually empty note
collection so it can render the dedicated message.

No search events or fields are added to `TideBloc`. Domain entities,
repositories, Drift storage, and migrations remain unchanged.

## Accessibility and Localization

- The search, clear, and close actions have localized semantic labels and
  tooltips.
- The search field has a localized hint.
- Search and clear icon controls preserve the existing minimum touch target.
- Keyboard focus moves to the field when search opens and remains there after
  clearing with `xmark`.
- English and Italian provide search hint, search action, clear action, close
  action, and no-results copy.
- Large text, compact-height keyboard layouts, and reduced-motion settings
  must remain usable without overflow.

## Verification

Widget tests cover:

- Font Awesome search action placement and opening behavior;
- automatic field focus and regular-header replacement;
- immediate case-insensitive substring filtering, including prefixes;
- preservation of the incoming note order;
- empty-query behavior;
- Font Awesome `xmark` visibility and clearing without closing;
- closing with localized `Cancella`/`Cancel`, query reset, and clean reopening;
- composer hiding with draft preservation;
- dedicated localized no-results state;
- compact-height mobile and wide macOS layouts;
- semantic labels, large text, and reduced-motion behavior.

Run `dart format`, `flutter analyze`, and the complete `flutter test` suite after
implementation.

## Acceptance Criteria

- A Font Awesome search icon is visible at the top right of the normal header.
- Opening search smoothly replaces the header and hides the composer.
- Results filter live against note content, including prefixes, without a
  submit action.
- The Font Awesome `xmark` clears the query without closing search.
- `Cancella`/`Cancel` closes search, clears the query, and restores the
  preserved composer.
- An empty query shows all notes; an unmatched query shows localized feedback.
- Search remains usable across supported mobile and macOS layouts and respects
  accessibility settings.
- Existing note behavior and persistence are unchanged.
