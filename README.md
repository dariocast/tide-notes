# Tide

[![CI](https://github.com/dariocast/tide-notes/actions/workflows/ci.yml/badge.svg)](https://github.com/dariocast/tide-notes/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/dariocast/tide-notes?include_prereleases&style=flat-square)](https://github.com/dariocast/tide-notes/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platform-Android%20%7C%20macOS%20%7C%20iOS-lightgrey?style=flat-square)](https://github.com/dariocast/tide-notes)

A calm, local-first single-stream notes app for capturing, reviewing, searching, and resurfacing thoughts.

Built around three core interactions:

1. **Append** a plain-text thought at the top.
2. **Review** notes as they visually sink down the stream.
3. **Rescue** a relevant note with a right swipe.

All notes remain 100% private and stored locally on your device in SQLite via [Drift](https://drift.simonbinder.eu/) — no cloud, no account, and no network connection required.

---

## 📱 Platforms

- **Android** (APKs available under [Releases](https://github.com/dariocast/tide-notes/releases))
- **macOS** (`.app` / `.zip` available under [Releases](https://github.com/dariocast/tide-notes/releases))
- **iOS**

---

## 🛠️ Development

### Prerequisites

- Flutter SDK 3.41+ (channel stable)
- Dart SDK 3.11+

### Setup

```bash
# Clone the repository
git clone https://github.com/dariocast/tide-notes.git
cd tide-notes

# Install dependencies
flutter pub get

# Generate Drift schema & database models
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

### Quality & Verification Checks

```bash
# Formatting
dart format --output=none --set-exit-if-changed lib test integration_test

# Design tokens lint
bash tool/design_token_lint.sh

# Static analysis
flutter analyze

# Unit and widget tests
flutter test

# Integration tests
flutter test integration_test/tide_flow_test.dart -d macos
```

---

## 🏗️ Architecture

Tide uses **Clean Architecture** with strict layer boundaries:

- `lib/core`: App theme, design tokens, error models, and pure utilities.
- `lib/data`: Drift SQLite schema, migrations, generated DAOs, persistence models, and repository implementations.
- `lib/domain`: Pure Dart entities, repository contracts, and business use cases.
- `lib/presentation`: `flutter_bloc` state management, responsive pages, and custom rendering widgets.

---

## 📦 Releases

Refer to [RELEASING.md](RELEASING.md) for details on the automated CI/CD release workflow and versioning practices.

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are warmly welcomed!
Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting a PR.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
