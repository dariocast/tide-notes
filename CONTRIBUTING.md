# Contributing to Tide

Thank you for your interest in contributing to Tide! We welcome contributions to make Tide a better, calmer, and more reliable local-first notes experience.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- Dart SDK 3.11+
- For Android: Android Studio and Android SDK 21+
- For macOS/iOS: Xcode 15+ and CocoaPods

### Local Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/dariocast/tide-notes.git
   cd tide-notes
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Drift models and database code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Development & Testing Workflow

Before submitting a Pull Request, make sure all quality checks pass locally:

```bash
# 1. Format code according to Dart guidelines
dart format --output=none --set-exit-if-changed lib test integration_test

# 2. Verify design token compliance
bash tool/design_token_lint.sh

# 3. Run static analysis
flutter analyze

# 4. Run automated unit & widget tests
flutter test
```

## Architecture Guidelines

Tide uses **Clean Architecture** with layer-first boundaries:

- `lib/core`: Theme, error definitions, and pure helpers.
- `lib/data`: Drift schema, persistence entities, and local repository implementations.
- `lib/domain`: Pure Dart entities, use cases, and repository interfaces.
- `lib/presentation`: Bloc state management, pages, and presentation widgets.

> **Important**:
> - Domain code must never import Flutter or data layer files.
> - Presentation layer must never access data sources directly.
> - Visual literals (colors, dimensions, curves) must live in `lib/design` or design tokens.

## Submitting Pull Requests

1. Create a branch from `develop`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Commit with clear, conventional messages (e.g. `feat: add markdown preview`, `fix: correct swipe gesture margin`).
3. Ensure all tests pass.
4. Push to your fork and open a Pull Request targeting the `develop` branch.

## Code of Conduct

Please review and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) in all project interactions.
