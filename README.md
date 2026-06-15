# Loadstash

**Your prompts, curated and your own, usable in any app.**

Loadstash is a local-first Android app that keeps your best AI prompts one tap away — inside any app on your phone. Select text, tap Loadstash in the long-press menu, pick a prompt, fill in variables, and it drops straight into the field.

---

## Features

- **Works in any app** — integrates via Android's `ACTION_PROCESS_TEXT` (long-press selection menu) and a keyboard-triggered floating bubble
- **Variable fill-in** — wrap any part of a prompt in `{{double braces}}` and Loadstash shows a fill-in sheet before inserting
- **Folder organisation** — nested folder structure (Writing › Email › Cold), breadcrumb navigation
- **App-aware ranking** — prompts used in Claude surface first in Claude; prompts used in ChatGPT surface first in ChatGPT
- **Custom model tags** — tag prompts for Claude, ChatGPT, Gemini, or any model you add, with custom colours
- **Quick Add** — save a prompt directly from the overlay without switching to the main app
- **APM-compatible import/export** — share prompt packs as `.zip` files using the [Agent Package Manager](https://microsoft.github.io/apm/) `.prompt.md` format
- **Light & dark theme**
- **100% local** — nothing leaves your device

---

## Screenshots

<!-- Add screenshots here -->

---

## Getting Started

### Prerequisites

- Flutter 3.x (`flutter --version`)
- Android device or emulator running API 26+
- Android Studio or VS Code with Flutter extension

### Installation

```bash
git clone https://github.com/your-username/loadstash.git
cd loadstash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Running tests

```bash
flutter test
```

---

## Architecture

```
lib/
  core/          — theme tokens, animation primitives
  data/          — Drift SQLite database, repositories
  features/      — screens (library, overlay, editor, onboarding, settings)
  providers/     — Riverpod state providers
  services/      — business logic (variable detection, import/export, model tags)
android/         — native Android (BubbleService, AccessibilityService, ProcessTextActivity)
```

Key technologies: **Flutter · Dart · Drift (SQLite) · Riverpod · go_router**

---

## Contributing

We welcome contributions of all kinds — bug fixes, new features, documentation, and starter prompt packs. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Security

For security vulnerabilities, see [SECURITY.md](SECURITY.md) and follow the responsible disclosure process.

---

## License

Copyright 2026 Kushal Agrawal. Licensed under the [Apache License, Version 2.0](LICENSE).
