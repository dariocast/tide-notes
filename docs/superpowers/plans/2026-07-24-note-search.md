# Tide Note Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a live, localized note-content search that replaces Tide's header, temporarily collapses the composer without losing its draft, and filters the stream as the user types.

**Architecture:** Keep the query and search-mode lifecycle local to `TidePage`; derive visible notes synchronously through a pure presentation helper and leave `TideBloc`, repositories, and storage unchanged. Add focused header and empty-state widgets, while `TideShell` owns the state-preserving composer collapse and compact-height header rule.

**Tech Stack:** Flutter Material, `flutter_bloc`, Font Awesome Flutter, custom Tide design tokens/localizations, Flutter unit and widget tests.

---

## File Map

- Create `lib/presentation/search/note_search.dart`: pure, order-preserving content filter.
- Create `lib/presentation/widgets/tide_search_header.dart`: search field, Font Awesome clear action, and localized close action.
- Modify `lib/presentation/pages/tide_page.dart`: ephemeral controller/focus/search state, header switching, and filtered stream wiring.
- Modify `lib/presentation/widgets/tide_header.dart`: top-right Font Awesome search action.
- Modify `lib/presentation/widgets/tide_shell.dart`: keep search visible in compact heights and collapse the mounted composer.
- Modify `lib/presentation/widgets/note_stream.dart`: select regular-empty or no-search-results content.
- Modify `lib/presentation/widgets/tide_empty_state.dart`: add the focused no-search-results state without duplicating layout.
- Modify `lib/design/tide_icons.dart`: shared `magnifyingGlass` and `xmark` icons.
- Modify `lib/design/design_tokens.dart`: centralized search transition duration.
- Modify `lib/l10n/tide_localizations.dart`: English and Italian search copy.
- Create `test/presentation/search/note_search_test.dart`: matching-rule unit tests.
- Create `test/presentation/widgets/tide_search_header_test.dart`: control, focus, Font Awesome, and localization tests.
- Modify `test/presentation/pages/tide_page_test.dart`: end-to-end search-mode and result behavior.
- Modify `test/presentation/widgets/tide_shell_test.dart`: compact-height and state-preserving collapse coverage.

### Task 1: Add the pure note-content filter

**Files:**
- Create: `test/presentation/search/note_search_test.dart`
- Create: `lib/presentation/search/note_search.dart`

- [ ] **Step 1: Write failing matching-rule tests**

Create `test/presentation/search/note_search_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/domain/entities/note.dart';
import 'package:tide/presentation/search/note_search.dart';

void main() {
  final timestamp = DateTime(2026, 7, 24, 12);

  Note note(String id, String content) => Note(
    id: id,
    content: content,
    createdAt: timestamp,
    updatedAt: timestamp,
    surfacedAt: timestamp,
    rescueCount: 0,
  );

  test('empty or whitespace query returns every note in source order', () {
    final notes = [
      note('newest', 'Call Alice'),
      note('middle', 'todo: buy milk'),
      note('oldest', 'Read later'),
    ];

    expect(filterNotesByContent(notes, ''), notes);
    expect(filterNotesByContent(notes, '   '), notes);
  });

  test('matches a trimmed case-insensitive substring including prefix', () {
    final matchingFirst = note('first', 'TODO: Buy Milk');
    final nonMatching = note('second', 'Call Alice');
    final matchingLast = note('third', 'todo: buy train tickets');

    expect(
      filterNotesByContent(
        [matchingFirst, nonMatching, matchingLast],
        '  ToDo: BuY  ',
      ),
      [matchingFirst, matchingLast],
    );
  });

  test('preserves internal whitespace and treats diacritics as significant', () {
    final oneSpace = note('one', 'book train');
    final twoSpaces = note('two', 'book  train');
    final accented = note('three', 'caffè');

    expect(filterNotesByContent([oneSpace, twoSpaces], 'book  train'), [
      twoSpaces,
    ]);
    expect(filterNotesByContent([accented], 'caffe'), isEmpty);
  });
}
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
flutter test test/presentation/search/note_search_test.dart
```

Expected: FAIL because `package:tide/presentation/search/note_search.dart` and `filterNotesByContent` do not exist.

- [ ] **Step 3: Implement the minimal pure filter**

Create `lib/presentation/search/note_search.dart`:

```dart
import '../../domain/entities/note.dart';

List<Note> filterNotesByContent(List<Note> notes, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return notes;

  return notes
      .where(
        (note) => note.content.toLowerCase().contains(normalizedQuery),
      )
      .toList(growable: false);
}
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run:

```bash
flutter test test/presentation/search/note_search_test.dart
```

Expected: all 3 tests PASS.

- [ ] **Step 5: Commit the matching unit**

```bash
git add lib/presentation/search/note_search.dart test/presentation/search/note_search_test.dart
git commit -m "feat: add note content search matching"
```

### Task 2: Build the localized Font Awesome search controls

**Files:**
- Create: `test/presentation/widgets/tide_search_header_test.dart`
- Create: `lib/presentation/widgets/tide_search_header.dart`
- Modify: `lib/design/tide_icons.dart`
- Modify: `lib/l10n/tide_localizations.dart`

- [ ] **Step 1: Write failing widget tests for clear, focus, and Italian close copy**

Create `test/presentation/widgets/tide_search_header_test.dart` with a small
stateful harness that rebuilds when the controller changes:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_helpers.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/design/tide_icons.dart';
import 'package:tide/l10n/tide_localizations.dart';
import 'package:tide/presentation/widgets/tide_search_header.dart';

void main() {
  testWidgets('Font Awesome xmark clears text and keeps search focused', (
    tester,
  ) async {
    await tester.pumpWidget(const _SearchHarness(initialText: 'todo'));
    await tester.tap(find.byKey(const ValueKey('search-input')));
    await tester.pump();

    expect(find.byIcon(TideIcons.clearSearch.data), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clear-search')));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('search-input')),
    );
    expect(field.controller!.text, isEmpty);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.byIcon(TideIcons.clearSearch.data), findsNothing);
  });

  testWidgets('Italian search header exposes localized controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _SearchHarness(
        locale: Locale('it'),
        initialText: 'nota',
      ),
    );

    expect(find.text('Cerca nelle note…'), findsOneWidget);
    expect(find.byTooltip('Cancella testo di ricerca'), findsOneWidget);
    expect(find.text('Cancella'), findsOneWidget);
  });
}

class _SearchHarness extends StatefulWidget {
  const _SearchHarness({
    this.locale = const Locale('en'),
    this.initialText = '',
  });

  final Locale locale;
  final String initialText;

  @override
  State<_SearchHarness> createState() => _SearchHarnessState();
}

class _SearchHarnessState extends State<_SearchHarness> {
  late final TextEditingController controller;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: widget.locale,
    supportedLocales: const [Locale('en'), Locale('it')],
    localizationsDelegates: const [
      TideLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: TideAppTheme.foam,
    home: Scaffold(
      body: GSizeClassScope(
        sizeClass: GSizeClass.compact,
        child: TideSearchHeader(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) => setState(() {}),
          onClear: () {
            controller.clear();
            setState(() {});
            focusNode.requestFocus();
          },
          onClose: () {},
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run the widget test and verify RED**

Run:

```bash
flutter test test/presentation/widgets/tide_search_header_test.dart
```

Expected: FAIL because `TideSearchHeader`, `TideIcons.clearSearch`, and the
search localization strings do not exist.

- [ ] **Step 3: Add the shared Font Awesome icon vocabulary**

Add to `TideIcons` in `lib/design/tide_icons.dart`:

```dart
static const search = FontAwesomeIcons.magnifyingGlass;
static const clearSearch = FontAwesomeIcons.xmark;
```

- [ ] **Step 4: Add explicit English and Italian search copy**

Add to `TideLocalizations` in `lib/l10n/tide_localizations.dart`:

```dart
String get searchNotes => isItalian ? 'Cerca note' : 'Search notes';
String get searchHint =>
    isItalian ? 'Cerca nelle note…' : 'Search notes…';
String get clearSearch => isItalian
    ? 'Cancella testo di ricerca'
    : 'Clear search text';
String get closeSearch => isItalian ? 'Cancella' : 'Cancel';
String get noSearchResultsTitle =>
    isItalian ? 'Nessuna nota trovata.' : 'No notes found.';
String get noSearchResultsBody => isItalian
    ? 'Prova con una ricerca diversa.'
    : 'Try a different search.';
```

Keep the existing `cancel` getter unchanged because it labels confirmation
dialogs with `Annulla` in Italian; search uses the separate `closeSearch`
getter.

- [ ] **Step 5: Implement the focused search-header widget**

Create `lib/presentation/widgets/tide_search_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../l10n/tide_localizations.dart';

class TideSearchHeader extends StatelessWidget {
  const TideSearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final compact = sizeClassOf(context) == GSizeClass.compact;
    final colors = tideColorsOf(context);
    final l10n = TideLocalizations.of(context);

    return Padding(
      key: const ValueKey('search-header'),
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s3,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: FocusRing(
              borderRadius: GShapes.control,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  border: Border.all(color: colors.lineSubtle),
                  borderRadius: GShapes.control,
                ),
                child: TextField(
                  key: const ValueKey('search-input'),
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: const Center(
                      widthFactor: 1,
                      child: FaIcon(TideIcons.search, size: 16),
                    ),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('clear-search'),
                            tooltip: l10n.clearSearch,
                            onPressed: onClear,
                            icon: const FaIcon(
                              TideIcons.clearSearch,
                              size: 18,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GSpace.s2),
          TextButton(
            key: const ValueKey('close-search'),
            onPressed: onClose,
            child: Text(l10n.closeSearch),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run the focused widget test and verify GREEN**

Run:

```bash
flutter test test/presentation/widgets/tide_search_header_test.dart
```

Expected: both widget tests PASS with no overflow or framework exceptions.

- [ ] **Step 7: Commit the reusable controls**

```bash
git add lib/design/tide_icons.dart lib/l10n/tide_localizations.dart lib/presentation/widgets/tide_search_header.dart test/presentation/widgets/tide_search_header_test.dart
git commit -m "feat: add localized search header controls"
```

### Task 3: Add search mode and preserve the composer

**Files:**
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `test/presentation/widgets/tide_shell_test.dart`
- Modify: `lib/design/design_tokens.dart`
- Modify: `lib/presentation/widgets/tide_header.dart`
- Modify: `lib/presentation/widgets/tide_shell.dart`
- Modify: `lib/presentation/pages/tide_page.dart`

- [ ] **Step 1: Write failing page tests for opening, placement, and closing**

Add these tests to `test/presentation/pages/tide_page_test.dart`:

```dart
testWidgets('top-right Font Awesome search action replaces regular header', (
  tester,
) async {
  await pumpPage(tester, notes: [makeNote('one')]);
  await tester.pump();

  final search = find.byKey(const ValueKey('open-search'));
  final settings = find.bySemanticsLabel('Appearance settings');
  expect(find.byIcon(TideIcons.search.data), findsOneWidget);
  expect(
    tester.getCenter(search).dx,
    greaterThan(tester.getCenter(settings).dx),
  );

  await tester.tap(search);
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('search-input')), findsOneWidget);
  expect(find.byKey(const ValueKey('tide-title')), findsNothing);
  expect(settings, findsNothing);
  expect(
    tester
        .widget<TextField>(find.byKey(const ValueKey('search-input')))
        .focusNode!
        .hasFocus,
    isTrue,
  );
  expect(
    tester.getSize(find.byKey(const ValueKey('composer-transition'))).height,
    0,
  );
});

testWidgets('closing search resets the query and preserves composer draft', (
  tester,
) async {
  await pumpPage(tester, notes: [makeNote('one')]);
  final composer = find.byKey(const ValueKey('composer-input'));
  await tester.enterText(composer, 'unfinished draft');

  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('search-input')),
    'one',
  );
  await tester.tap(find.byKey(const ValueKey('close-search')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('search-input')), findsNothing);
  expect(find.byKey(const ValueKey('tide-title')), findsOneWidget);
  expect(tester.widget<TextField>(composer).controller!.text, 'unfinished draft');

  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();
  expect(
    tester
        .widget<TextField>(find.byKey(const ValueKey('search-input')))
        .controller!
        .text,
    isEmpty,
  );
});
```

- [ ] **Step 2: Write a failing shell test for compact-height search**

Extend the `pumpShell` helper in
`test/presentation/widgets/tide_shell_test.dart` with
`double height = 800` and `bool searching = false`, use
`Size(width, height)`, and pass `searching: searching` into `TideShell`.
Then add:

```dart
testWidgets('compact-height search keeps header and collapses composer', (
  tester,
) async {
  await pumpShell(
    tester,
    platform: TargetPlatform.android,
    width: 800,
    height: 180,
    searching: true,
  );
  await tester.pumpAndSettle();

  expect(find.text('header'), findsOneWidget);
  expect(
    tester.getSize(find.byKey(const ValueKey('composer-transition'))).height,
    0,
  );
  expect(find.text('stream'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```bash
flutter test test/presentation/pages/tide_page_test.dart test/presentation/widgets/tide_shell_test.dart
```

Expected: FAIL because there is no search action or page search mode, and
`TideShell` does not accept `searching`.

- [ ] **Step 4: Add a tokenized reveal duration**

Add to `GMotion` in `lib/design/design_tokens.dart`:

```dart
static const reveal = Duration(milliseconds: 180);
```

- [ ] **Step 5: Add the top-right action to `TideHeader`**

Add the Font Awesome and shared-icon imports, require an `onSearch` callback,
and build the action:

```dart
final VoidCallback onSearch;

final searchButton = Semantics(
  label: l10n.searchNotes,
  button: true,
  child: IconButton(
    key: const ValueKey('open-search'),
    tooltip: l10n.searchNotes,
    onPressed: onSearch,
    icon: const FaIcon(TideIcons.search, size: 18),
  ),
);
```

In the compact row, replace the trailing fixed `SizedBox.square` with
`searchButton`. In the expanded row, place the settings control and search
action in this order so search remains at the far right:

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    TideSettingsButton(
      onExport: onExport,
      onDeleteAll: onDeleteAll,
    ),
    const SizedBox(width: GSpace.s1),
    searchButton,
  ],
)
```

- [ ] **Step 6: Teach `TideShell` to collapse without disposing**

Add a defaulted field to `TideShell`:

```dart
this.searching = false,

final bool searching;
```

Add this helper to `_TideShellState`:

```dart
Widget _composerRegion(BuildContext context) => _region(
  _composerKey,
  TweenAnimationBuilder<double>(
    tween: Tween(end: widget.searching ? 0 : 1),
    duration: context.motion.duration(GMotion.reveal),
    curve: GMotion.settle,
    builder: (context, factor, child) => ClipRect(
      key: const ValueKey('composer-transition'),
      child: Align(
        heightFactor: factor,
        child: IgnorePointer(
          ignoring: widget.searching,
          child: ExcludeSemantics(
            excluding: widget.searching,
            child: child,
          ),
        ),
      ),
    ),
    child: widget.composer,
  ),
);
```

Pass `BuildContext` into `_buildVertical`, replace both direct composer
regions with `_composerRegion(context)`, and keep the header in a short
vertical viewport while searching:

```dart
if (constraints.maxHeight >= 240 || widget.searching)
  _region(_headerKey, widget.header),
_composerRegion(context),
```

Use `_composerRegion(context)` in the desktop sidebar as well. The composer
widget remains the tween's stable `child`, preserving its controller and
draft.

- [ ] **Step 7: Give `TidePage` the local search lifecycle**

Convert `TidePage` to a `StatefulWidget`, move the existing `BlocConsumer`
build into `_TidePageState`, and add:

```dart
late final TextEditingController _searchController;
late final FocusNode _searchFocusNode;
bool _searching = false;

@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _searchFocusNode = FocusNode();
}

@override
void dispose() {
  _searchController.dispose();
  _searchFocusNode.dispose();
  super.dispose();
}

void _openSearch() {
  setState(() => _searching = true);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _searchFocusNode.requestFocus();
  });
}

void _searchChanged(String value) => setState(() {});

void _clearSearch() {
  _searchController.clear();
  setState(() {});
  _searchFocusNode.requestFocus();
}

void _closeSearch() {
  _searchController.clear();
  _searchFocusNode.unfocus();
  setState(() => _searching = false);
}
```

Build the animated header in `_TidePageState`:

```dart
Widget _buildHeader(
  BuildContext context,
  TideState state,
) => AnimatedSize(
  duration: context.motion.duration(GMotion.reveal),
  curve: GMotion.settle,
  child: AnimatedSwitcher(
    duration: context.motion.duration(GMotion.reveal),
    switchInCurve: GMotion.settle,
    switchOutCurve: GMotion.settle,
    child: _searching
        ? TideSearchHeader(
            key: const ValueKey('active-search-header'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _searchChanged,
            onClear: _clearSearch,
            onClose: _closeSearch,
          )
        : TideHeader(
            key: const ValueKey('regular-header'),
            noteCount: state.notes.length,
            now: widget.now(),
            onSearch: _openSearch,
            onExport: () => context.read<TideBloc>().add(
              NotesExportRequested(state.notes),
            ),
            onDeleteAll: () => context.read<TideBloc>().add(
              const NotesDeleteAllRequested(),
            ),
          ),
  ),
);
```

Import `design_tokens.dart` and `tide_search_header.dart`. Replace the existing
inline `TideHeader` with `_buildHeader(context, state)`, pass
`searching: _searching` to `TideShell`, and change existing `now`/`haptic`
references in the state class to `widget.now`/`widget.haptic`.

- [ ] **Step 8: Run focused tests and verify GREEN**

Run:

```bash
flutter test test/presentation/pages/tide_page_test.dart test/presentation/widgets/tide_shell_test.dart
```

Expected: search-mode tests and all pre-existing page/shell tests PASS.

- [ ] **Step 9: Commit the mode transition**

```bash
git add lib/design/design_tokens.dart lib/presentation/pages/tide_page.dart lib/presentation/widgets/tide_header.dart lib/presentation/widgets/tide_shell.dart test/presentation/pages/tide_page_test.dart test/presentation/widgets/tide_shell_test.dart
git commit -m "feat: add animated note search mode"
```

### Task 4: Filter the stream live and render no-results feedback

**Files:**
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `lib/presentation/pages/tide_page.dart`
- Modify: `lib/presentation/widgets/note_stream.dart`
- Modify: `lib/presentation/widgets/tide_empty_state.dart`

- [ ] **Step 1: Let page tests create content independently from IDs**

Replace the local helper in `test/presentation/pages/tide_page_test.dart`:

```dart
Note makeNote(String id, {String? content}) => Note(
  id: id,
  content: content ?? id,
  createdAt: timestamp,
  updatedAt: timestamp,
  surfacedAt: timestamp,
  rescueCount: 0,
);
```

- [ ] **Step 2: Write failing live-filter and no-results tests**

Add:

```dart
testWidgets('search filters content immediately and preserves note order', (
  tester,
) async {
  Finder noteCard(String id) => find.byWidgetPredicate(
    (widget) => widget is NoteCard && widget.note.id == id,
  );
  await pumpPage(
    tester,
    notes: [
      makeNote('first', content: 'TODO: Buy Milk'),
      makeNote('second', content: 'Call Alice'),
      makeNote('third', content: 'todo: buy train tickets'),
    ],
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const ValueKey('search-input')),
    '  ToDo: BuY  ',
  );
  await tester.pump();

  expect(noteCard('first'), findsOneWidget);
  expect(noteCard('second'), findsNothing);
  expect(noteCard('third'), findsOneWidget);
  expect(
    tester.getTopLeft(noteCard('first')).dy,
    lessThan(tester.getTopLeft(noteCard('third')).dy),
  );
});

testWidgets('xmark restores all notes without closing search', (tester) async {
  Finder noteCard(String id) => find.byWidgetPredicate(
    (widget) => widget is NoteCard && widget.note.id == id,
  );
  await pumpPage(
    tester,
    notes: [
      makeNote('first', content: 'alpha'),
      makeNote('second', content: 'beta'),
    ],
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('search-input')),
    'alpha',
  );
  await tester.pump();

  await tester.tap(find.byKey(const ValueKey('clear-search')));
  await tester.pump();

  expect(find.byKey(const ValueKey('search-input')), findsOneWidget);
  expect(noteCard('first'), findsOneWidget);
  expect(noteCard('second'), findsOneWidget);
});

testWidgets('unmatched query shows dedicated feedback', (tester) async {
  await pumpPage(tester, notes: [makeNote('one', content: 'alpha')]);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('search-input')),
    'missing',
  );
  await tester.pump();

  expect(find.byKey(const ValueKey('search-empty-state')), findsOneWidget);
  expect(find.text('No notes found.'), findsOneWidget);
  expect(find.textContaining('stream is quiet'), findsNothing);
});
```

- [ ] **Step 3: Run the page tests and verify RED**

Run:

```bash
flutter test test/presentation/pages/tide_page_test.dart
```

Expected: FAIL because `TidePage` still passes the complete list and
`NoteStream` has no search-specific empty state.

- [ ] **Step 4: Add a no-results variant without duplicating empty layout**

Refactor `lib/presentation/widgets/tide_empty_state.dart` so the existing
`TideEmptyState` delegates to a private shared layout, then add:

```dart
class TideNoSearchResults extends StatelessWidget {
  const TideNoSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    return _TideEmptyContent(
      key: const ValueKey('search-empty-state'),
      title: l10n.noSearchResultsTitle,
      body: l10n.noSearchResultsBody,
    );
  }
}

class _TideEmptyContent extends StatelessWidget {
  const _TideEmptyContent({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = tideColorsOf(context);
    final compact = sizeClassOf(context) == GSizeClass.compact;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? GSpace.s4 : GSpace.s6,
          GSpace.s7,
          compact ? GSpace.s4 : GSpace.s6,
          GSpace.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: GSpace.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: GLayout.contentNarrow,
              ),
              child: Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

The existing `TideEmptyState.build` becomes:

```dart
@override
Widget build(BuildContext context) {
  final l10n = TideLocalizations.of(context);
  return _TideEmptyContent(
    title: l10n.emptyTitle,
    body: l10n.emptyBody,
  );
}
```

- [ ] **Step 5: Let `NoteStream` select the correct empty state**

Add a defaulted constructor parameter and field:

```dart
this.showNoSearchResults = false,

final bool showNoSearchResults;
```

Replace the empty-list branch with:

```dart
stream = KeyedSubtree(
  key: const ValueKey('note-list'),
  child: showNoSearchResults
      ? const TideNoSearchResults()
      : const TideEmptyState(),
);
```

- [ ] **Step 6: Derive and pass live results from `TidePage`**

Import `../search/note_search.dart`. At the start of the successful
`BlocConsumer` builder, after the fatal-failure branch, derive:

```dart
final visibleNotes = _searching
    ? filterNotesByContent(state.notes, _searchController.text)
    : state.notes;
final showNoSearchResults =
    _searching &&
    _searchController.text.trim().isNotEmpty &&
    visibleNotes.isEmpty;
```

Pass `visibleNotes` and the flag to `NoteStream`:

```dart
stream: NoteStream(
  notes: visibleNotes,
  showNoSearchResults: showNoSearchResults,
  busyNoteIds: state.busyNoteIds,
  haptic: widget.haptic,
  now: widget.now,
  undoNoteId: state.rescueReceipt?.noteId,
  onUndo: () =>
      context.read<TideBloc>().add(const RescueUndoRequested()),
  onChanged: (edit) => context.read<TideBloc>().add(
    NoteEditRequested(edit.id, edit.content),
  ),
  onRescue: (id) =>
      context.read<TideBloc>().add(NoteRescueRequested(id)),
),
```

- [ ] **Step 7: Run focused unit and page tests and verify GREEN**

Run:

```bash
flutter test test/presentation/search/note_search_test.dart test/presentation/pages/tide_page_test.dart
```

Expected: matching, live-filter, clear, ordering, and no-results tests PASS.

- [ ] **Step 8: Commit live results**

```bash
git add lib/presentation/pages/tide_page.dart lib/presentation/widgets/note_stream.dart lib/presentation/widgets/tide_empty_state.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: filter note stream during search"
```

### Task 5: Cover localization, responsive layouts, and reduced motion

**Files:**
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `test/presentation/widgets/tide_shell_test.dart`

- [ ] **Step 1: Write the Italian feedback test**

Add to `test/presentation/pages/tide_page_test.dart`:

```dart
testWidgets('Italian search localizes field, close, and no-results feedback', (
  tester,
) async {
  final appearance = AppearanceController.inMemory(
    language: TideLanguageSelection.italian,
  );
  await pumpPage(
    tester,
    notes: [makeNote('one', content: 'alpha')],
    appearance: appearance,
  );
  await tester.pump();

  await tester.tap(find.bySemanticsLabel('Cerca note'));
  await tester.pumpAndSettle();
  expect(find.text('Cerca nelle note…'), findsOneWidget);
  expect(find.text('Cancella'), findsOneWidget);

  await tester.enterText(
    find.byKey(const ValueKey('search-input')),
    'assente',
  );
  await tester.pump();
  expect(find.text('Nessuna nota trovata.'), findsOneWidget);
});
```

- [ ] **Step 2: Write wide macOS, compact-height, and reduced-motion tests**

Add to `test/presentation/pages/tide_page_test.dart`:

```dart
testWidgets('search remains usable in the wide macOS sidebar', (tester) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    debugDefaultTargetPlatformOverride = null;
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 800);
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

  await pumpPage(tester, notes: [makeNote('one')]);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();

  final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
  expect(
    find.descendant(
      of: sidebar,
      matching: find.byKey(const ValueKey('search-input')),
    ),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
});

testWidgets('reduced motion switches to search in one frame', (tester) async {
  await pumpPage(
    tester,
    mediaQuery: const MediaQueryData(disableAnimations: true),
  );
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pump();

  expect(find.byKey(const ValueKey('search-input')), findsOneWidget);
  expect(find.byKey(const ValueKey('tide-title')), findsNothing);
});
```

The compact-height behavior remains covered by the shell test added in Task 3.

- [ ] **Step 3: Extend accessibility coverage while search is active**

In the existing
`large text and theme modes meet accessibility guidelines` test, after the
first light-theme checks, open search and check the active controls:

```dart
await tester.tap(find.byKey(const ValueKey('open-search')));
await tester.pumpAndSettle();
await tester.enterText(
  find.byKey(const ValueKey('search-input')),
  'query',
);
await tester.pump();
expect(tester.takeException(), isNull);
await expectLater(tester, meetsGuideline(textContrastGuideline));
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
```

- [ ] **Step 4: Run responsive/accessibility tests and verify GREEN**

Run:

```bash
flutter test test/presentation/pages/tide_page_test.dart test/presentation/widgets/tide_shell_test.dart
```

Expected: all tests PASS with no overflow, unlabeled action, contrast, or tap
target failures.

- [ ] **Step 5: Commit the cross-layout coverage**

```bash
git add test/presentation/pages/tide_page_test.dart test/presentation/widgets/tide_shell_test.dart
git commit -m "test: cover responsive note search"
```

### Task 6: Format and verify the complete application

**Files:**
- Verify all files changed in Tasks 1–5.

- [ ] **Step 1: Format production and test files**

Run:

```bash
dart format lib/presentation/search/note_search.dart lib/presentation/pages/tide_page.dart lib/presentation/widgets/tide_header.dart lib/presentation/widgets/tide_search_header.dart lib/presentation/widgets/tide_shell.dart lib/presentation/widgets/note_stream.dart lib/presentation/widgets/tide_empty_state.dart lib/design/tide_icons.dart lib/design/design_tokens.dart lib/l10n/tide_localizations.dart test/presentation/search/note_search_test.dart test/presentation/widgets/tide_search_header_test.dart test/presentation/widgets/tide_shell_test.dart test/presentation/pages/tide_page_test.dart
```

Expected: formatter exits 0.

- [ ] **Step 2: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: exit 0 with `No issues found!`.

- [ ] **Step 3: Run the complete test suite**

Run:

```bash
flutter test
```

Expected: exit 0 with every unit and widget test passing.

- [ ] **Step 4: Inspect final scope and whitespace**

Run:

```bash
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors; only search production/test files and this
approved documentation remain in scope.

- [ ] **Step 5: Commit formatter-only changes if formatting modified files**

If `dart format` changed tracked content after Task 5:

```bash
git add lib test
git commit -m "style: format note search implementation"
```

If formatting made no changes, do not create an empty commit.
