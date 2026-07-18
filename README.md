# Tide

Tide is an offline-first single-stream notes app built around three moves:

1. **Append** a plain-text thought at the top.
2. **Review** notes as they visually sink down the stream.
3. **Rescue** a relevant note with a right swipe.

MVP targets iOS, Android, and macOS. Notes stay local in SQLite through Drift; no network, account, or sync is required.

## Development

```bash
flutter pub get
dart run build_runner build
flutter run
```

Run checks:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/tide_flow_test.dart -d macos
```

Profile smoke test (10,000 seeded notes, automated continuous scroll for 30 seconds):

```bash
flutter drive --profile -d macos \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/tide_profile_test.dart
```

Verified on 2026-07-19: completed without crashes, framework exceptions, test-observable scrolling stalls, or eager mounting; fewer than 100 note rows remained mounted throughout.

## Architecture

The code uses Clean Architecture with layer-first boundaries:

- `lib/core`: theme, errors, and pure utilities;
- `lib/data`: Drift schema, generated code, persistence models, and local repository;
- `lib/domain`: pure-Dart entities, repository contract, and use cases;
- `lib/presentation`: TideBloc, page, and rendering widgets.

`flutter_bloc` owns business and async state. Dependencies use constructor injection, `RepositoryProvider`, and `BlocProvider`. Domain code never imports Flutter or data models; presentation never accesses data sources.

After changing Drift schema or annotations, regenerate `lib/data/datasources/local/tide_database.g.dart`:

```bash
dart run build_runner build
```

After replacing `assets/icon/tide-app-icon.png`, regenerate Android, iOS, and macOS launcher icons:

```bash
dart run flutter_launcher_icons
```

## MVP boundaries

This release intentionally excludes cloud sync, accounts, folders, persistent tags, filters, search, attachments, Markdown, archive, deletion, analytics, onboarding, and complex settings. These boundaries keep future sync behind `NoteRepository` without requiring presentation or domain rewrites.
