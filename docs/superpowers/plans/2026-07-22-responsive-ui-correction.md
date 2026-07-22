# Tide Responsive UI Correction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore Tide's clean baseline by removing recent visual regressions, using system typography, introducing a macOS-specific split workspace, and exposing `Tide` consistently as the product name.

**Architecture:** Keep business state and interactions in `TidePage`, but move responsive composition into a focused `TideShell` widget with a pure platform-and-width decision. Shared header, composer, undo, and stream widgets render in either vertical or desktop split composition. Theme and native metadata stay independent from presentation behavior.

**Tech Stack:** Flutter 3, Dart, Material 3, flutter_bloc, flutter_test, Android/iOS/macOS native configuration

---

## File Map

- Create `lib/presentation/widgets/tide_shell.dart`: own platform/width selection and both compositions.
- Create `test/presentation/widgets/tide_shell_test.dart`: cover selection and rendered variants.
- Create `test/platform_display_name_test.dart`: verify native user-visible names.
- Modify `lib/presentation/pages/tide_page.dart`: bind BLoC state/actions to `TideShell`.
- Modify `lib/presentation/widgets/tide_header.dart`: remove decorative glyph.
- Modify `lib/presentation/widgets/tide_empty_state.dart`: keep text-only guidance.
- Modify `lib/design/design_helpers.dart`: remove glyph/corner painters.
- Modify `lib/design/design_tokens.dart`: remove dead decoration values; add desktop dimensions.
- Modify `lib/design/theme.dart`: use platform system font throughout.
- Modify `pubspec.yaml`: remove custom-font registration.
- Delete five files under `assets/fonts/`: remove unused custom-font binaries.
- Modify design/page/app tests: lock restored visual contracts.
- Modify Android, iOS, macOS display-name configuration: use `Tide`.

Pre-existing changes in `macos/Podfile.lock` and `macos/Runner.xcodeproj/project.pbxproj` belong to user. Never stage them during task commits.

### Task 1: Remove Decorations and Unify Typography

**Files:**
- Modify: `test/design/design_system_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `lib/presentation/widgets/tide_header.dart`
- Modify: `lib/presentation/widgets/tide_empty_state.dart`
- Modify: `lib/design/design_helpers.dart`
- Modify: `lib/design/design_tokens.dart`
- Modify: `lib/design/theme.dart`
- Modify: `pubspec.yaml`
- Delete: `assets/fonts/InstrumentSerif-Regular.ttf`
- Delete: `assets/fonts/Manrope-Regular.ttf`
- Delete: `assets/fonts/Manrope-Medium.ttf`
- Delete: `assets/fonts/Manrope-SemiBold.ttf`
- Delete: `assets/fonts/Manrope-Bold.ttf`

- [ ] **Step 1: Write failing system-font test**

Add to `test/design/design_system_test.dart`:

```dart
  test('all application text roles inherit the platform system font', () {
    for (final theme in [GravityAppTheme.light, GravityAppTheme.dark]) {
      final styles = <TextStyle?>[
        theme.textTheme.displaySmall,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelSmall,
      ];
      expect(styles.every((style) => style?.fontFamily == null), isTrue);
    }
  });
```

- [ ] **Step 2: Write failing no-decoration test**

Import `TideHeader` and `TideEmptyState` in `test/presentation/pages/tide_page_test.dart`, then add:

```dart
  testWidgets('header and empty state contain no decorative painting', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(
      find.descendant(
        of: find.byType(TideHeader),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(TideEmptyState),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(find.text('⌘'), findsNothing);
    expect(find.text('↵'), findsNothing);
  });
```

- [ ] **Step 3: Confirm tests expose regressions**

Run:

```bash
flutter test test/design/design_system_test.dart test/presentation/pages/tide_page_test.dart
```

Expected: FAIL. Theme declares custom families; header/empty state contain custom painting and keycaps.

- [ ] **Step 4: Make header and empty state text-only**

Replace header title row in `lib/presentation/widgets/tide_header.dart`:

```dart
                Text(
                  'Tide',
                  key: const ValueKey('tide-title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
```

Replace `TideEmptyState.build` in `lib/presentation/widgets/tide_empty_state.dart`:

```dart
  @override
  Widget build(BuildContext context) {
    final g = gravityOf(context);
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
              'Your stream is quiet.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: GSpace.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: GLayout.contentNarrow),
              child: Text(
                'Capture anything above. Append freely, review what sinks, rescue what still matters.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: g.textMuted),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
```

Delete private `_Kbd` from that file.

- [ ] **Step 5: Delete obsolete visual API**

Delete `TideGlyph`, `_TideGlyphPainter`, `MastheadFrame`, and `_CornerMarkPainter` from `lib/design/design_helpers.dart`.

Replace `GDecor` in `lib/design/design_tokens.dart`:

```dart
abstract final class GDecor {
  static const crossSize = 19.0,
      crossThickness = 1.0,
      crossOffset = 14.0,
      railWidth = 2.5,
      hairline = 1.0;
  static const hoverAlpha = 0.05,
      pressAlpha = 0.09,
      bloomAlpha = 0.55,
      swipeGlyphAlpha = 0.16;
}
```

Delete `cornerInk` from `GLight`, `GDark`, `GravityTheme` constructor/fields, light/dark constants, and `lerp`. No other palette field changes.

- [ ] **Step 6: Restore system typography**

Remove every `fontFamily` argument from text styles in `lib/design/theme.dart`. Keep size, weight, height, spacing, color.

Delete `flutter.fonts` block from `pubspec.yaml`. Delete all five font files listed under Task 1.

- [ ] **Step 7: Format and verify focused tests**

```bash
dart format lib/design lib/presentation/widgets test/design test/presentation/pages
flutter test test/design/design_system_test.dart test/presentation/pages/tide_page_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit Task 1 only**

```bash
git add lib/design/design_helpers.dart lib/design/design_tokens.dart lib/design/theme.dart lib/presentation/widgets/tide_header.dart lib/presentation/widgets/tide_empty_state.dart pubspec.yaml test/design/design_system_test.dart test/presentation/pages/tide_page_test.dart
git add -A assets/fonts
git commit -m "fix: restore clean system typography"
```

### Task 2: Build Platform-Aware Shell

**Files:**
- Create: `lib/presentation/widgets/tide_shell.dart`
- Create: `test/presentation/widgets/tide_shell_test.dart`
- Modify: `lib/design/design_tokens.dart`

- [ ] **Step 1: Write failing layout tests**

Create `test/presentation/widgets/tide_shell_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/design/design_tokens.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/presentation/widgets/tide_shell.dart';

void main() {
  test('only wide macOS uses desktop split layout', () {
    expect(
      tideShellLayoutFor(TargetPlatform.macOS, GLayout.bpExpanded),
      TideShellLayout.desktopSplit,
    );
    expect(
      tideShellLayoutFor(TargetPlatform.macOS, GLayout.bpExpanded - 1),
      TideShellLayout.vertical,
    );
    expect(
      tideShellLayoutFor(TargetPlatform.iOS, 1200),
      TideShellLayout.vertical,
    );
    expect(
      tideShellLayoutFor(TargetPlatform.android, 1200),
      TideShellLayout.vertical,
    );
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required TargetPlatform platform,
    required double width,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: GravityAppTheme.light,
        home: Scaffold(
          body: TideShell(
            platform: platform,
            header: const SizedBox(key: ValueKey('header')),
            composer: const SizedBox(key: ValueKey('composer')),
            undoAction: const SizedBox(key: ValueKey('undo')),
            stream: const SizedBox(key: ValueKey('stream')),
          ),
        ),
      ),
    );
  }

  testWidgets('wide macOS renders split workspace', (tester) async {
    await pumpShell(tester, platform: TargetPlatform.macOS, width: 1200);
    expect(find.byKey(const ValueKey('desktop-split-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('vertical-layout')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('desktop-sidebar'))).width,
      GLayout.desktopSidebar,
    );
  });

  testWidgets('narrow macOS and wide mobile stay vertical', (tester) async {
    await pumpShell(
      tester,
      platform: TargetPlatform.macOS,
      width: GLayout.bpExpanded - 1,
    );
    expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);

    await pumpShell(tester, platform: TargetPlatform.iOS, width: 1200);
    expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-split-layout')), findsNothing);
  });
}
```

- [ ] **Step 2: Confirm missing API**

```bash
flutter test test/presentation/widgets/tide_shell_test.dart
```

Expected: compilation FAIL because shell types and desktop tokens do not exist.

- [ ] **Step 3: Add desktop dimensions**

Replace `GLayout`:

```dart
abstract final class GLayout {
  static const contentMax = 720.0,
      contentNarrow = 640.0,
      contentWide = 800.0,
      desktopMax = 1040.0,
      desktopSidebar = 336.0,
      headerHeight = 72.0,
      minTouchTarget = 48.0,
      bpMedium = 600.0,
      bpExpanded = 840.0;
}
```

- [ ] **Step 4: Implement isolated shell**

Create `lib/presentation/widgets/tide_shell.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

enum TideShellLayout { vertical, desktopSplit }

TideShellLayout tideShellLayoutFor(TargetPlatform platform, double width) {
  if (platform == TargetPlatform.macOS && width >= GLayout.bpExpanded) {
    return TideShellLayout.desktopSplit;
  }
  return TideShellLayout.vertical;
}

class TideShell extends StatelessWidget {
  const TideShell({
    super.key,
    required this.header,
    required this.composer,
    required this.undoAction,
    required this.stream,
    this.platform,
  });

  final Widget header;
  final Widget composer;
  final Widget undoAction;
  final Widget stream;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mode = tideShellLayoutFor(
        platform ?? defaultTargetPlatform,
        constraints.maxWidth,
      );
      return mode == TideShellLayout.desktopSplit
          ? _desktop(context)
          : _vertical();
    },
  );

  Widget _vertical() => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: GLayout.contentMax),
      child: FocusTraversalGroup(
        child: Column(
          key: const ValueKey('vertical-layout'),
          children: [
            header,
            composer,
            undoAction,
            const Hairline(indent: GSpace.s4),
            Expanded(child: stream),
          ],
        ),
      ),
    ),
  );

  Widget _desktop(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: GLayout.desktopMax),
      child: FocusTraversalGroup(
        child: Row(
          key: const ValueKey('desktop-split-layout'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('desktop-sidebar'),
              width: GLayout.desktopSidebar,
              child: Column(children: [header, composer, undoAction]),
            ),
            SizedBox(
              width: GDecor.hairline,
              child: ColoredBox(color: gravityOf(context).lineSubtle),
            ),
            Expanded(child: stream),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 5: Format, test, commit**

```bash
dart format lib/presentation/widgets/tide_shell.dart test/presentation/widgets/tide_shell_test.dart lib/design/design_tokens.dart
flutter test test/presentation/widgets/tide_shell_test.dart
git add lib/design/design_tokens.dart lib/presentation/widgets/tide_shell.dart test/presentation/widgets/tide_shell_test.dart
git commit -m "feat: add adaptive Tide shell"
```

Expected: tests PASS; commit contains three named files.

### Task 3: Integrate Shell with Tide State

**Files:**
- Modify: `lib/presentation/pages/tide_page.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`

- [ ] **Step 1: Write failing page integration tests**

Import `flutter/foundation.dart` and `tide_shell.dart`. Replace old `ConstrainedBox` assertion in the lean-shell test:

```dart
    expect(find.byType(TideShell), findsOneWidget);
    expect(find.byKey(const ValueKey('vertical-layout')), findsOneWidget);
    expect(find.text('Tide'), findsOneWidget);
    expect(find.textContaining('2 notes captured'), findsOneWidget);
    expect(find.textContaining('Jul 19'), findsOneWidget);
```

Add:

```dart
  testWidgets('wide macOS puts controls beside note stream', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await pumpPage(tester, notes: [makeNote('one')]);
    await tester.pump();

    expect(find.byKey(const ValueKey('desktop-split-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-sidebar')), findsOneWidget);
    expect(find.byType(NoteCard), findsOneWidget);
  });
```

- [ ] **Step 2: Confirm old page composition fails**

```bash
flutter test test/presentation/pages/tide_page_test.dart
```

Expected: FAIL because page does not render `TideShell`.

- [ ] **Step 3: Bind page content to shell**

Import `../widgets/tide_shell.dart` in `lib/presentation/pages/tide_page.dart`. Replace successful scaffold's current `SafeArea` child with:

```dart
          child: SafeArea(
            child: TideShell(
              header: TideHeader(noteCount: state.notes.length, now: now()),
              composer: NoteComposer(
                appendCompleted: state.appendCompleted,
                onSubmit: (content) => context.read<TideBloc>().add(
                  NoteAppendRequested(content),
                ),
              ),
              undoAction: state.rescueReceipt == null
                  ? const SizedBox(height: GSpace.s2)
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          GSpace.s4,
                          0,
                          GSpace.s4,
                          GSpace.s2,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () => context.read<TideBloc>().add(
                            const RescueUndoRequested(),
                          ),
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Undo rescue'),
                        ),
                      ),
                    ),
              stream: NoteStream(
                notes: state.notes,
                busyNoteIds: state.busyNoteIds,
                haptic: haptic,
                now: now,
                onChanged: (edit) => context.read<TideBloc>().add(
                  NoteEditRequested(edit.id, edit.content),
                ),
                onRescue: (id) => context.read<TideBloc>().add(
                  NoteRescueRequested(id),
                ),
              ),
            ),
          ),
```

Keep `design_helpers.dart` for `PaperBackground`. Keep `design_tokens.dart` for undo spacing.

- [ ] **Step 4: Format, test, commit**

```bash
dart format lib/presentation/pages/tide_page.dart test/presentation/pages/tide_page_test.dart
flutter test test/presentation/pages/tide_page_test.dart test/presentation/widgets/tide_shell_test.dart test/presentation/pages/rescue_flow_test.dart
git add lib/presentation/pages/tide_page.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: adapt Tide layout for macOS"
```

Expected: all selected tests PASS; append/edit/rescue remain unchanged.

### Task 4: Normalize Product Display Name

**Files:**
- Create: `test/platform_display_name_test.dart`
- Modify: `test/app_test.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `macos/Runner/Configs/AppInfo.xcconfig`

- [ ] **Step 1: Write failing native-name test**

Create `test/platform_display_name_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native launchers expose Tide with uppercase T', () {
    final android = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();
    final macos = File(
      'macos/Runner/Configs/AppInfo.xcconfig',
    ).readAsStringSync();

    expect(android, contains('android:label="Tide"'));
    expect(
      ios,
      contains('<key>CFBundleName</key>\n\t<string>Tide</string>'),
    );
    expect(macos, contains('PRODUCT_NAME = Tide'));
  });
}
```

Add to `test/app_test.dart` after reading `MaterialApp`:

```dart
    expect(app.title, 'Tide');
```

- [ ] **Step 2: Confirm lowercase metadata fails**

```bash
flutter test test/platform_display_name_test.dart test/app_test.dart
```

Expected: platform test FAILS for Android, iOS bundle name, macOS; Flutter title passes.

- [ ] **Step 3: Change display values only**

Use these exact values:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
android:label="Tide"

<!-- ios/Runner/Info.plist -->
<key>CFBundleName</key>
<string>Tide</string>
```

```text
# macos/Runner/Configs/AppInfo.xcconfig
PRODUCT_NAME = Tide
```

Do not change `app.tidenotes.tide`, Dart package name, or Drift DB name.

- [ ] **Step 4: Format, test, commit exact files**

```bash
dart format test/platform_display_name_test.dart test/app_test.dart
flutter test test/platform_display_name_test.dart test/app_test.dart
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist macos/Runner/Configs/AppInfo.xcconfig test/platform_display_name_test.dart test/app_test.dart
git commit -m "fix: normalize Tide display name"
```

Expected: PASS; pre-existing macOS lock/project changes excluded.

### Task 5: Full Verification

**Files:**
- No planned source changes.

- [ ] **Step 1: Confirm obsolete symbols are gone**

```bash
rg -n "TideGlyph|MastheadFrame|_CornerMarkPainter|InstrumentSerif|fontFamily: 'Manrope'|cornerInk|glyphStroke|cornerMark" lib pubspec.yaml test
```

Expected: no matches.

- [ ] **Step 2: Check formatting and design-token discipline**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
tool/design_token_lint.sh
```

Expected: both exit 0; token lint reports no forbidden visual literals.

- [ ] **Step 3: Run static analysis and full test suite**

```bash
flutter analyze
flutter test
```

Expected: `No issues found!`; all tests PASS.

- [ ] **Step 4: Build both form-factor targets**

```bash
flutter build macos
flutter build apk --debug
```

Expected: successful `Tide.app` and debug APK builds.

- [ ] **Step 5: Audit final workspace**

```bash
git status --short --branch
git diff --check
git diff --stat
```

Expected: no whitespace errors. Pre-existing `macos/Podfile.lock` and `macos/Runner.xcodeproj/project.pbxproj` changes remain uncommitted unless separately reviewed and proven necessary.
