# Tide Organic Visual Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Tide's rigid warm baseline with an Atlantic, rounded, branded visual foundation featuring Quicksand/Nunito, Foam/Deep Tide/Abyss themes, viewport-relative sinking, OS-driven motion, and leaner high-value tests.

**Architecture:** Keep domain and BLoC behavior unchanged. Centralize the new palettes and typography under `lib/design`, represent theme choice independently from Flutter's three-value `ThemeMode`, wrap only the scrolling stream in a contrast-safe shader, and pass editing state through presentation callbacks. Preserve the responsive shell and its stateful region reparenting.

**Tech Stack:** Flutter 3 / Dart, Material 3, shared_preferences, flutter_bloc, bundled Google Fonts variable TTF assets under SIL Open Font License 1.1

---

## File Map

- Create `assets/fonts/Quicksand-Variable.ttf`: pinned Quicksand variable font.
- Create `assets/fonts/Nunito-Variable.ttf`: pinned Nunito variable font.
- Create `assets/fonts/OFL-Quicksand.txt` and `assets/fonts/OFL-Nunito.txt`: upstream license notices.
- Create `assets/fonts/SOURCES.md`: pinned upstream commit and raw-source URLs.
- Create `lib/design/tide_depth_fade.dart`: viewport fade model and shader wrapper.
- Create `lib/presentation/widgets/tide_settings.dart`: mobile sheet and macOS theme popover.
- Create `test/design/tide_depth_fade_test.dart`: pure depth/contrast rules and widget bypass coverage.
- Modify `lib/design/design_tokens.dart`: Atlantic palettes, OLED theme, radii, fade floors.
- Modify `lib/design/theme.dart`: Quicksand/Nunito type scale and rounded component defaults.
- Modify `lib/design/appearance_controller.dart`: four-state Tide theme selection; remove manual motion state.
- Modify `lib/design/design_helpers.dart`: OS-only `TideMotionPolicy`; OLED background handling.
- Modify `lib/app.dart`: map Tide theme selection to MaterialApp themes.
- Modify `lib/presentation/widgets/tide_header.dart`: responsive organic app bar and settings entry.
- Modify `lib/presentation/widgets/note_composer.dart`: rounded shallow composer.
- Modify `lib/presentation/widgets/note_card.dart`: flat row, soft hover/focus, editing-state callback.
- Modify `lib/presentation/widgets/note_stream.dart`: own editing set and wrap list in depth fade.
- Modify `lib/presentation/widgets/tide_empty_state.dart`: new branded type scale.
- Modify `lib/presentation/widgets/prefix_text.dart`: Atlantic prefix palette.
- Modify `lib/presentation/pages/tide_page.dart`: no behavior change; consume updated widgets.
- Modify `pubspec.yaml`: register bundled fonts.
- Consolidate tests under `test/design` and `test/presentation`; retain all business-layer suites.

Search, repository interfaces, Drift schema, use cases, BLoC events/state, and native product metadata are out of scope.

### Task 1: Atlantic Palettes and Branded Typography

**Files:**
- Create: `assets/fonts/Quicksand-Variable.ttf`
- Create: `assets/fonts/Nunito-Variable.ttf`
- Create: `assets/fonts/OFL-Quicksand.txt`
- Create: `assets/fonts/OFL-Nunito.txt`
- Create: `assets/fonts/SOURCES.md`
- Modify: `pubspec.yaml`
- Modify: `lib/design/design_tokens.dart`
- Modify: `lib/design/theme.dart`
- Modify: `lib/design/design_helpers.dart`
- Modify: `lib/app.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `lib/presentation/widgets/note_composer.dart`
- Modify: `lib/presentation/widgets/prefix_text.dart`
- Modify: `lib/presentation/widgets/tide_empty_state.dart`
- Modify: `lib/presentation/widgets/tide_header.dart`
- Modify: `lib/presentation/widgets/tide_shell.dart`
- Modify: `test/design/design_system_test.dart`
- Modify: `test/app_test.dart`
- Modify: `test/presentation/pages/rescue_flow_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`
- Modify: `test/presentation/widgets/prefix_text_test.dart`
- Modify: `test/presentation/widgets/tide_shell_test.dart`

- [ ] **Step 1: Write failing palette and typography contracts**

Replace the old warm/system-font assertions in `test/design/design_system_test.dart` with parameterized contracts:

```dart
test('Tide themes expose Foam, Deep Tide, and true-black Abyss', () {
  expect(TideColors.foam.bgTop, const Color(0xFFF7FBFC));
  expect(TideColors.deepTide.bgBottom, const Color(0xFF041319));
  expect(TideColors.abyss.bgTop, Colors.black);
  expect(TideColors.abyss.bgMid, Colors.black);
  expect(TideColors.abyss.bgBottom, Colors.black);
  expect(TideAppTheme.abyss.scaffoldBackgroundColor, Colors.black);
});

test('Tide type roles use only Quicksand and Nunito', () {
  for (final theme in [
    TideAppTheme.foam,
    TideAppTheme.deepTide,
    TideAppTheme.abyss,
  ]) {
    expect(theme.textTheme.titleLarge?.fontFamily, 'Quicksand');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Quicksand');
    for (final style in [
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
      theme.textTheme.bodySmall,
      theme.textTheme.labelLarge,
      theme.textTheme.labelSmall,
    ]) {
      expect(style?.fontFamily, 'Nunito');
    }
  }
});
```

- [ ] **Step 2: Run red test**

Run:

```bash
flutter test test/design/design_system_test.dart
```

Expected: compile failure because `TideColors` and Foam/Deep Tide/Abyss theme getters do not exist.

- [ ] **Step 3: Download pinned official font assets and licenses**

Run:

```bash
mkdir -p assets/fonts
curl -L https://raw.githubusercontent.com/google/fonts/c4d10b2a6e42723c8bbac29eef4fcadf855764b6/ofl/quicksand/Quicksand%5Bwght%5D.ttf -o assets/fonts/Quicksand-Variable.ttf
curl -L https://raw.githubusercontent.com/google/fonts/604936664fd62c14271209b51f98e7f495dd1a3e/ofl/nunito/Nunito%5Bwght%5D.ttf -o assets/fonts/Nunito-Variable.ttf
curl -L https://raw.githubusercontent.com/google/fonts/c4d10b2a6e42723c8bbac29eef4fcadf855764b6/ofl/quicksand/OFL.txt -o assets/fonts/OFL-Quicksand.txt
curl -L https://raw.githubusercontent.com/google/fonts/604936664fd62c14271209b51f98e7f495dd1a3e/ofl/nunito/OFL.txt -o assets/fonts/OFL-Nunito.txt
```

Create `assets/fonts/SOURCES.md`:

```markdown
# Font sources

- Quicksand 3.006 variable font and OFL 1.1 license: google/fonts commit `c4d10b2a6e42723c8bbac29eef4fcadf855764b6`.
- Nunito 3.602 variable font and OFL 1.1 license: google/fonts commit `604936664fd62c14271209b51f98e7f495dd1a3e`.

Files are bundled locally; Tide performs no runtime font download.
```

- [ ] **Step 4: Register both variable families**

Add under `flutter:` in `pubspec.yaml`:

```yaml
  fonts:
    - family: Quicksand
      fonts:
        - asset: assets/fonts/Quicksand-Variable.ttf
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Variable.ttf
```

- [ ] **Step 5: Replace warm palette classes with Atlantic palettes**

In `lib/design/design_tokens.dart`, replace `GLight`, `GDark`, and `GravityTheme` with `GFoam`, `GDeepTide`, `GAbyss`, and `TideColors`. Use these exact anchor values:

```dart
abstract final class GFoam {
  static const bgTop = Color(0xFFF7FBFC);
  static const bgMid = Color(0xFFEEF6F7);
  static const bgBottom = Color(0xFFE3EFF1);
  static const surface = Color(0xFFFAFDFD);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const ink = Color(0xFF102F3A);
  static const textSecondary = Color(0xFF214A55);
  static const textMuted = Color(0xFF1E424B);
  static const accent = Color(0xFF1A7180);
  static const accentMuted = Color(0xFF69AAB3);
  static const accentSubtle = Color(0xFFD7EAED);
  static const textOnAccent = Color(0xFFF6FCFD);
  static const rescue = Color(0xFF3F7F72);
  static const rescueSoft = Color(0xFFD9EBE6);
  static const prefixWarm = Color(0xFFAD6A66);
  static const danger = Color(0xFFA9565B);
  static const dangerSoft = Color(0xFFF4E1E3);
  static const lineSubtle = Color(0x1F102F3A);
  static const lineStrong = Color(0x52102F3A);
  static const depthFloor = 0.80;
}

abstract final class GDeepTide {
  static const bgTop = Color(0xFF0C242B);
  static const bgMid = Color(0xFF081C22);
  static const bgBottom = Color(0xFF041319);
  static const surface = Color(0xFF0B232A);
  static const surfaceElevated = Color(0xFF102C34);
  static const ink = Color(0xFFE8F4F5);
  static const textSecondary = Color(0xFFC6DEE1);
  static const textMuted = Color(0xFFA7C3C8);
  static const accent = Color(0xFF55A9B5);
  static const accentMuted = Color(0xFF477C85);
  static const accentSubtle = Color(0xFF183B43);
  static const textOnAccent = Color(0xFF04171C);
  static const rescue = Color(0xFF6AAE9E);
  static const rescueSoft = Color(0xFF173B35);
  static const prefixWarm = Color(0xFFC1847F);
  static const danger = Color(0xFFD78386);
  static const dangerSoft = Color(0xFF3A2025);
  static const lineSubtle = Color(0x24E8F4F5);
  static const lineStrong = Color(0x5CE8F4F5);
  static const depthFloor = 0.72;
}

abstract final class GAbyss {
  static const bgTop = Colors.black;
  static const bgMid = Colors.black;
  static const bgBottom = Colors.black;
  static const surface = Colors.black;
  static const surfaceElevated = Color(0xFF071419);
  static const ink = Color(0xFFEDF8F8);
  static const textSecondary = Color(0xFFC9E1E3);
  static const textMuted = Color(0xFFA8C6C8);
  static const accent = Color(0xFF62B2BD);
  static const accentMuted = Color(0xFF4A7E86);
  static const accentSubtle = Color(0xFF102D33);
  static const textOnAccent = Color(0xFF001014);
  static const rescue = Color(0xFF70B5A5);
  static const rescueSoft = Color(0xFF102F29);
  static const prefixWarm = Color(0xFFC98B86);
  static const danger = Color(0xFFE18A8E);
  static const dangerSoft = Color(0xFF35191E);
  static const lineSubtle = Color(0x2AEDF8F8);
  static const lineStrong = Color(0x66EDF8F8);
  static const depthFloor = 0.70;
}
```

`TideColors` exposes exactly `bgTop`, `bgMid`, `bgBottom`, `surface`, `surfaceElevated`, `ink`, `textSecondary`, `textMuted`, `accent`, `accentMuted`, `accentSubtle`, `textOnAccent`, `rescue`, `rescueSoft`, `prefixWarm`, `danger`, `dangerSoft`, `lineSubtle`, `lineStrong`, `isOled`, and `depthFloor`. It provides static `foam`, `deepTide`, and `abyss` and lerps every color plus `depthFloor`; `isOled` switches at the midpoint. Delete obsolete `textGhost`, `dotNeutral`, `archive`, and `archiveSoft`. Keep spacing/layout token values. Add:

```dart
abstract final class GRadii {
  static const control = 14.0;
  static const composer = 20.0;
  static const pill = 999.0;
}

abstract final class GShapes {
  static const control = BorderRadius.all(Radius.circular(GRadii.control));
  static const composer = BorderRadius.all(Radius.circular(GRadii.composer));
  static const pill = BorderRadius.all(Radius.circular(GRadii.pill));
}
```

- [ ] **Step 6: Build the Quicksand/Nunito theme**

Rename `GravityAppTheme` to `TideAppTheme` and expose:

```dart
static ThemeData get foam => _build(Brightness.light, TideColors.foam);
static ThemeData get deepTide => _build(Brightness.dark, TideColors.deepTide);
static ThemeData get abyss => _build(Brightness.dark, TideColors.abyss);
```

Use the approved roles:

```dart
final text = TextTheme(
  headlineMedium: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 30,
    height: 1.20,
    fontWeight: FontWeight.w500,
    color: colors.ink,
  ),
  titleLarge: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w400,
    color: colors.ink,
  ),
  bodyLarge: TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    height: 1.50,
    fontWeight: FontWeight.w400,
    color: colors.textSecondary,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'Nunito',
    fontSize: 17,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: colors.ink,
  ),
  bodySmall: TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: colors.textMuted,
  ),
  labelLarge: const TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
  ),
  labelSmall: TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: colors.textMuted,
  ),
);
```

Apply `fontFamilyFallback: const ['.AppleSystemUIFont', 'Roboto', 'sans-serif']` to every branded role. Fill uncustomized roles from Nunito defaults so all 15 roles remain non-null. Replace the zero-radius component shape with `RoundedRectangleBorder(borderRadius: GShapes.control)`.

Update all consumers in this task's file list: `GravityTheme` → `TideColors`, `GravityAppTheme.light` → `TideAppTheme.foam`, `GravityAppTheme.dark` → `TideAppTheme.deepTide`, `GLight` → `GFoam`, `GDark` → `GDeepTide`, and `gravityOf` → `tideColorsOf`. Replace `archive` prefix access with `prefixWarm`. This keeps the repository compiling at the Task 1 checkpoint.

- [ ] **Step 7: Format and verify Task 1**

Run:

```bash
flutter pub get
dart format lib/design test/design
flutter test test/design/design_system_test.dart
flutter analyze
```

Expected: design test passes; analyzer reports no issues.

- [ ] **Step 8: Commit Task 1**

```bash
git add assets/fonts pubspec.yaml pubspec.lock lib/design/design_tokens.dart lib/design/theme.dart lib/design/design_helpers.dart lib/app.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_composer.dart lib/presentation/widgets/prefix_text.dart lib/presentation/widgets/tide_empty_state.dart lib/presentation/widgets/tide_header.dart lib/presentation/widgets/tide_shell.dart test/design/design_system_test.dart test/app_test.dart test/presentation/pages/rescue_flow_test.dart test/presentation/pages/tide_page_test.dart test/presentation/widgets/note_card_test.dart test/presentation/widgets/prefix_text_test.dart test/presentation/widgets/tide_shell_test.dart
git commit -m "feat: add Atlantic themes and Tide typography"
```

### Task 2: Four-State Theme Selection and Organic Settings

**Files:**
- Modify: `lib/design/appearance_controller.dart`
- Modify: `lib/app.dart`
- Create: `lib/presentation/widgets/tide_settings.dart`
- Modify: `lib/presentation/widgets/tide_header.dart`
- Modify: `test/design/appearance_controller_test.dart`
- Modify: `test/app_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`

- [ ] **Step 1: Write failing theme-selection tests**

Replace motion persistence coverage in `test/design/appearance_controller_test.dart`:

```dart
test('appearance restores and persists all Tide theme selections', () async {
  for (final selection in TideThemeSelection.values) {
    SharedPreferences.setMockInitialValues({'tide_theme': selection.name});
    final controller = await AppearanceController.load();
    expect(controller.selection, selection);
  }

  SharedPreferences.setMockInitialValues({});
  final controller = await AppearanceController.load();
  await controller.setSelection(TideThemeSelection.abyss);
  expect((await AppearanceController.load()).selection, TideThemeSelection.abyss);
});

test('invalid persisted selection falls back to system', () async {
  SharedPreferences.setMockInitialValues({'tide_theme': 'unknown'});
  expect(
    (await AppearanceController.load()).selection,
    TideThemeSelection.system,
  );
});
```

Add app mapping assertions in `test/app_test.dart`: System uses Foam + Deep Tide with `ThemeMode.system`; Foam uses light; Deep Tide uses dark; Abyss uses `TideAppTheme.abyss` and `ThemeMode.dark`.

- [ ] **Step 2: Run red tests**

```bash
flutter test test/design/appearance_controller_test.dart test/app_test.dart
```

Expected: compile failure because `TideThemeSelection` and selection mapping do not exist.

- [ ] **Step 3: Replace ThemeMode/motion persistence with Tide selection**

In `lib/design/appearance_controller.dart` implement:

```dart
enum TideThemeSelection { system, foam, deepTide, abyss }

class AppearanceController extends ChangeNotifier {
  AppearanceController._(this._preferences, this._selection);

  static const _themeKey = 'tide_theme';
  final SharedPreferences? _preferences;
  TideThemeSelection _selection;

  TideThemeSelection get selection => _selection;

  static Future<AppearanceController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeKey);
      final selection = TideThemeSelection.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => TideThemeSelection.system,
      );
      return AppearanceController._(preferences, selection);
    } catch (_) {
      return AppearanceController.inMemory();
    }
  }

  factory AppearanceController.inMemory({
    TideThemeSelection selection = TideThemeSelection.system,
  }) => AppearanceController._(null, selection);

  Future<void> setSelection(TideThemeSelection value) async {
    if (_selection == value) return;
    _selection = value;
    notifyListeners();
    try {
      await _preferences?.setString(_themeKey, value.name);
    } catch (_) {}
  }
}
```

Retain `AppearanceScope`; delete `_motionKey`, `motionEnabled`, `setMotionEnabled`, and old `theme_mode` writes.

- [ ] **Step 4: Map selection in TideApp**

In `lib/app.dart`, derive:

```dart
final selection = _appearance.selection;
final themeMode = switch (selection) {
  TideThemeSelection.system => ThemeMode.system,
  TideThemeSelection.foam => ThemeMode.light,
  TideThemeSelection.deepTide || TideThemeSelection.abyss => ThemeMode.dark,
};
final darkTheme = selection == TideThemeSelection.abyss
    ? TideAppTheme.abyss
    : TideAppTheme.deepTide;
```

Build `MaterialApp(theme: TideAppTheme.foam, darkTheme: darkTheme, themeMode: themeMode)`.

- [ ] **Step 5: Create platform-adaptive settings control**

Create `lib/presentation/widgets/tide_settings.dart` with a `TideSettingsButton`. It reads `AppearanceScope`, shows a modal bottom sheet for iOS/Android and a `PopupMenuButton<TideThemeSelection>` for macOS. Both surfaces render exactly these labels:

```dart
const themeLabels = {
  TideThemeSelection.system: 'System',
  TideThemeSelection.foam: 'Foam',
  TideThemeSelection.deepTide: 'Deep Tide',
  TideThemeSelection.abyss: 'Abyss',
};
```

Each option includes explicit selected state and invokes `setSelection`. The button semantics label is `Appearance settings`. No motion option appears.

- [ ] **Step 6: Integrate settings and centered mobile title**

In `TideHeader`, replace the current menu. Compact header uses `TideSettingsButton`, centered `Tide`, and a right `SizedBox.square(dimension: GLayout.minTouchTarget)` spacer. Expanded/macOS header uses a left-aligned title/count column plus settings button. Keep localized count/date.

Add one mobile page test opening the sheet and selecting Abyss; assert `AppearanceController.selection`. Do not duplicate every theme option in widget tests because controller tests cover mapping.

- [ ] **Step 7: Verify and commit Task 2**

```bash
dart format lib/design/appearance_controller.dart lib/app.dart lib/presentation/widgets/tide_settings.dart lib/presentation/widgets/tide_header.dart test/design/appearance_controller_test.dart test/app_test.dart test/presentation/pages/tide_page_test.dart
flutter test test/design/appearance_controller_test.dart test/app_test.dart test/presentation/pages/tide_page_test.dart
git add lib/design/appearance_controller.dart lib/app.dart lib/presentation/widgets/tide_settings.dart lib/presentation/widgets/tide_header.dart test/design/appearance_controller_test.dart test/app_test.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: add Tide theme selection and settings"
```

### Task 3: OS-Driven Motion Policy

**Files:**
- Modify: `lib/design/design_helpers.dart`
- Modify: `lib/design/design_tokens.dart`
- Modify: `test/presentation/pages/rescue_flow_test.dart`
- Modify: `test/design/appearance_controller_test.dart`

- [ ] **Step 1: Write failing zero-duration test**

Replace the old “short transition” test in `rescue_flow_test.dart`:

```dart
testWidgets('OS reduced motion removes non-essential duration', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TideAppTheme.foam,
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: _MotionProbe(),
      ),
    ),
  );
  expect(
    tester.widget<AnimatedContainer>(find.byKey(const ValueKey('probe'))).duration,
    Duration.zero,
  );
});

class _MotionProbe extends StatelessWidget {
  const _MotionProbe();

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('probe'),
    duration: context.motion.duration(GMotion.color),
  );
}
```

`_MotionProbe` builds an `AnimatedContainer` whose duration is `context.motion.duration(GMotion.color)`.

- [ ] **Step 2: Run red test**

```bash
flutter test test/presentation/pages/rescue_flow_test.dart
```

Expected: FAIL because reduced motion still returns `GMotion.colorFast`.

- [ ] **Step 3: Implement OS-only policy**

Replace `GravityMotion` with:

```dart
class TideMotionPolicy {
  const TideMotionPolicy(this.context);
  final BuildContext context;

  bool get reduceMotion => MediaQuery.disableAnimationsOf(context);

  Duration duration(Duration normal) =>
      reduceMotion ? Duration.zero : normal;
}

extension TideContext on BuildContext {
  TideMotionPolicy get motion => TideMotionPolicy(this);
}
```

Remove the `appearance_controller.dart` import from `design_helpers.dart`. Delete unused perpetual `GMotion.float` and any other motion token with no consumer.

- [ ] **Step 4: Verify and commit Task 3**

```bash
dart format lib/design test/presentation/pages/rescue_flow_test.dart
flutter test test/design/appearance_controller_test.dart test/presentation/pages/rescue_flow_test.dart
git add lib/design/design_helpers.dart lib/design/design_tokens.dart test/design/appearance_controller_test.dart test/presentation/pages/rescue_flow_test.dart
git commit -m "fix: follow OS reduced motion preference"
```

### Task 4: Organic Header, Composer, Rows, and Empty State

**Files:**
- Modify: `lib/design/design_helpers.dart`
- Modify: `lib/presentation/widgets/note_composer.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `lib/presentation/widgets/prefix_text.dart`
- Modify: `lib/presentation/widgets/tide_empty_state.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`

- [ ] **Step 1: Write failing high-value component contracts**

Keep one note-row test and one page smoke test. Assert:

```dart
final composerSurface = tester.widget<DecoratedBox>(
  find.byKey(const ValueKey('composer-surface')),
);
final composerDecoration = composerSurface.decoration as BoxDecoration;
expect(composerDecoration.borderRadius, GShapes.composer);
expect(composerDecoration.boxShadow, isNull);
final noteRow = tester.widget<AnimatedContainer>(
  find.byKey(const ValueKey('note-row')),
);
final noteDecoration = noteRow.decoration as BoxDecoration;
expect(noteDecoration.border?.left, isNull);
expect(noteDecoration.borderRadius, isNull);
final noteContext = tester.element(find.byKey(const ValueKey('note-row')));
expect(Theme.of(noteContext).textTheme.bodyMedium?.fontFamily, 'Nunito');
expect(find.text('Tide'), findsOneWidget);
```

Add a hover assertion that the row wash equals `TideColors.foam.accentSubtle` with the shared hover alpha. Remove assertions tied to the old hard accent rail.

- [ ] **Step 2: Run red tests**

```bash
flutter test test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
```

Expected: FAIL on hard composer rail/shadow and note left border.

- [ ] **Step 3: Soften shared background and focus**

Update `PaperBackground` to use the Atlantic top-to-bottom gradient. For `colors.isOled`, render a plain `ColoredBox(color: Colors.black)`. Remove the radial bloom. Replace `FocusRing` glow with a rounded 2px outline using `colors.accent` and no shadow.

- [ ] **Step 4: Rebuild composer surface**

In `NoteComposer`, key the decorated field surface with `const ValueKey('composer-surface')`. Use `Border.all(color: colors.lineSubtle)`, radius `GShapes.composer`, no left rail, no shadow, and a circular `FilledButton` constrained to the minimum touch target. Retain controller, focus, multiline, submit behavior, and Command+Enter. Use only shape tokens from `lib/design` so `tool/design_token_lint.sh` remains green.

- [ ] **Step 5: Rebuild note rows and prefix palette**

In `NoteCard`, remove left rail and hover rail calculations. Keep only bottom hairline. Hover color becomes `colors.accentSubtle.withValues(alpha: GDecor.hoverAlpha)`. Focus/edit behavior stays intact. Rescue background uses `colors.rescueSoft` and one upward icon. Delete now-unused `GShadows`, `GDecor.bloomAlpha`, `GDecor.railWidth`, and shadow/rail tokens after `rg` confirms no consumer.

In `PrefixText`, use `[colors.accent, colors.rescue, colors.prefixWarm]`; keep deterministic hashing and unchanged semantics.

- [ ] **Step 6: Apply branded empty state**

Use `headlineMedium` Quicksand for `Your stream is quiet.` and Nunito `bodyLarge` for guidance. Keep text only and left alignment.

- [ ] **Step 7: Verify and commit Task 4**

```bash
dart format lib/design/design_helpers.dart lib/presentation/widgets test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
flutter test test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart test/presentation/pages/rescue_flow_test.dart
git add lib/design/design_helpers.dart lib/presentation/widgets/note_composer.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/prefix_text.dart lib/presentation/widgets/tide_empty_state.dart test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: soften Tide stream components"
```

### Task 5: Viewport-Relative Sinking

**Files:**
- Create: `lib/design/tide_depth_fade.dart`
- Create: `test/design/tide_depth_fade_test.dart`
- Modify: `lib/presentation/widgets/note_card.dart`
- Modify: `lib/presentation/widgets/note_stream.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`

- [ ] **Step 1: Write failing pure depth tests**

Create `test/design/tide_depth_fade_test.dart`:

```dart
void main() {
  test('depth is full through 65 percent then fades to theme floor', () {
    expect(TideDepthModel.opacityAt(0.0, floor: 0.8), 1);
    expect(TideDepthModel.opacityAt(0.65, floor: 0.8), 1);
    expect(TideDepthModel.opacityAt(0.825, floor: 0.8), closeTo(0.9, 0.001));
    expect(TideDepthModel.opacityAt(1.0, floor: 0.8), 0.8);
  });

  for (final (:name, :colors) in [
    (name: 'Foam', colors: TideColors.foam),
    (name: 'Deep Tide', colors: TideColors.deepTide),
    (name: 'Abyss', colors: TideColors.abyss),
  ]) {
    test('$name deepest metadata stays readable', () {
      final faded = Color.alphaBlend(
        colors.textMuted.withValues(alpha: colors.depthFloor),
        colors.bgBottom,
      );
      expect(contrast(faded, colors.bgBottom), greaterThanOrEqualTo(4.5));
    });
  }
}
```

- [ ] **Step 2: Write failing widget behavior tests**

Add tests proving:

- `TideDepthFade` contains a bottom-only `ShaderMask` when enabled;
- high-contrast `MediaQueryData(highContrast: true)` bypasses the shader;
- starting inline edit bypasses the shader;
- a note dragged upward changes from a fraction above 0.65 to below 0.65 while `TideDepthModel.opacityAt` returns a higher opacity.

- [ ] **Step 3: Run red tests**

```bash
flutter test test/design/tide_depth_fade_test.dart test/presentation/pages/tide_page_test.dart
```

Expected: compile failure because depth types do not exist.

- [ ] **Step 4: Implement pure depth model and shader**

Create `lib/design/tide_depth_fade.dart`:

```dart
abstract final class TideDepthModel {
  static const fullPresenceEnd = 0.65;

  static double opacityAt(double viewportFraction, {required double floor}) {
    final fraction = viewportFraction.clamp(0.0, 1.0);
    if (fraction <= fullPresenceEnd) return 1;
    final progress = (fraction - fullPresenceEnd) / (1 - fullPresenceEnd);
    return 1 - ((1 - floor) * progress);
  }
}

class TideDepthFade extends StatelessWidget {
  const TideDepthFade({
    super.key,
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = tideColorsOf(context);
    if (!enabled || MediaQuery.highContrastOf(context)) return child;
    return ShaderMask(
      key: const ValueKey('tide-depth-mask'),
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: colors.depthFloor),
        ],
        stops: const [0, TideDepthModel.fullPresenceEnd, 1],
      ).createShader(bounds),
      child: child,
    );
  }
}
```

- [ ] **Step 5: Plumb editing state without touching BLoC**

Add optional `ValueChanged<bool>? onEditingChanged` to `NoteCard`; call `true` in `_beginEditing` and `false` when focus loss ends editing.

Convert `NoteStream` to StatefulWidget with `Set<String> _editingIds`. Each card callback adds/removes its ID. In `didUpdateWidget`, remove editing IDs no longer present in `widget.notes`, preventing stale disabled fade when an edited row disappears. Wrap the empty state or list in:

```dart
TideDepthFade(
  enabled: _editingIds.isEmpty,
  child: stream,
)
```

Keep lazy `ListView.builder`, keys, scroll state, rescue behavior, and edit callbacks.

- [ ] **Step 6: Verify and commit Task 5**

```bash
dart format lib/design/tide_depth_fade.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_stream.dart test/design/tide_depth_fade_test.dart test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
flutter test test/design/tide_depth_fade_test.dart test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
git add lib/design/tide_depth_fade.dart lib/presentation/widgets/note_card.dart lib/presentation/widgets/note_stream.dart test/design/tide_depth_fade_test.dart test/presentation/widgets/note_card_test.dart test/presentation/pages/tide_page_test.dart
git commit -m "feat: add viewport-relative note depth"
```

### Task 6: Consolidate Tests and Verify the Foundation

**Files:**
- Modify: `test/presentation/widgets/tide_shell_test.dart`
- Modify: `test/presentation/pages/tide_page_test.dart`
- Modify: `test/presentation/widgets/note_card_test.dart`
- Modify: `audit-styles.md`

- [ ] **Step 1: Remove redundant implementation-detail tests**

In `tide_shell_test.dart`, retain:

- pure platform/breakpoint selection;
- one wide macOS split assertion;
- one wide mobile vertical assertion;
- composer draft/focus survival across resize.

Remove the separate child-order, divider-color, updated-child, and unbounded-height tests now covered by the responsive flows and shell contract.

In `tide_page_test.dart`, retain append, Meta+Enter, edit flush, lazy 10,000-note construction, one mobile smoke, one macOS accessibility flow, viewport fade, and semantic labels. Remove duplicate empty-state alignment, decoration absence, composer height, and standalone header-content assertions.

In `note_card_test.dart`, retain busy-rescue prevention, one flat-row/hover contract, one inline-edit contract, and parameterized deepest-fade contrast. Remove repeated surface geometry assertions.

- [ ] **Step 2: Update visual audit documentation**

Replace warm Gravity terminology in `audit-styles.md` with the Atlantic foundation map: Foam/Deep Tide/Abyss, Quicksand/Nunito, rounded composer, flat note stream, OS motion, and viewport-relative fade. State that search remains the next separate scope.

- [ ] **Step 3: Run the complete automated gate**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
tool/design_token_lint.sh
flutter analyze
flutter test
flutter build macos
flutter build apk --debug
```

Expected: all commands exit 0; macOS produces `Tide.app`; Android produces `app-debug.apk`.

- [ ] **Step 4: Perform four-target manual visual acceptance**

Run and inspect:

```bash
flutter run -d macos
```

Verify wide macOS Foam and Abyss. Then use emulator/simulator targets to verify compact iPhone Foam and compact Android Deep Tide. For each target confirm: centered/desktop header behavior, Quicksand/Nunito loading, rounded composer, flat stream, bottom-only fade recovery on scroll, settings theme selection, and no overflow.

- [ ] **Step 5: Audit final scope and commit**

```bash
rg -n "Gravity|motion_enabled|Reduce motion|Enable motion|GLight|GDark|GravityTheme|GravityAppTheme" lib test audit-styles.md
git status --short --branch
git diff --check
```

Expected: no obsolete production/test terminology or manual-motion strings; clean diff formatting.

Commit consolidation and audit:

```bash
git add test/presentation/widgets/tide_shell_test.dart test/presentation/pages/tide_page_test.dart test/presentation/widgets/note_card_test.dart audit-styles.md
git commit -m "test: consolidate Tide visual coverage"
```
