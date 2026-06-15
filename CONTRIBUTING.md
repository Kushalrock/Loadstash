# Contributing to Loadstash

Thank you for taking the time to contribute! This document explains how to get involved.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Report a Bug](#how-to-report-a-bug)
- [How to Request a Feature](#how-to-request-a-feature)
- [Development Setup](#development-setup)
- [Making a Pull Request](#making-a-pull-request)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Sharing Prompt Packs](#sharing-prompt-packs)

---

## Code of Conduct

By participating, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

---

## How to Report a Bug

1. **Search existing issues** first — your bug may already be tracked.
2. Open a new issue using the **Bug Report** template.
3. Include:
   - Android version and device model
   - Flutter version (`flutter --version`)
   - Steps to reproduce reliably
   - Expected vs actual behaviour
   - Crash logs if available (from `adb logcat`)

---

## How to Request a Feature

1. **Search existing issues** to avoid duplicates.
2. Open a new issue using the **Feature Request** template.
3. Describe the problem you're solving, not just the solution — this helps us understand the use case.

---

## Development Setup

```bash
# 1. Fork and clone
git clone https://github.com/your-username/loadstash.git
cd loadstash

# 2. Install dependencies
flutter pub get

# 3. Generate Drift code
dart run build_runner build --delete-conflicting-outputs

# 4. Run tests
flutter test

# 5. Run the app
flutter run
```

### Native Android (Kotlin)

The floating bubble and accessibility service live in `android/app/src/main/kotlin/`. You need Android Studio or the Android command-line tools to build the native layer. A standard `flutter run` handles this automatically.

---

## Making a Pull Request

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Write tests** for any new behaviour. The test suite lives in `test/`.

3. **Keep changes focused** — one feature or fix per PR. Large changes are hard to review.

4. **Run the full suite** before opening the PR:
   ```bash
   flutter test
   flutter analyze
   flutter build apk --debug
   ```

5. **Open the PR** against `main` and fill in the pull request template.

6. A maintainer will review your PR. Please be responsive to feedback — PRs with no activity for 30 days may be closed.

---

## Coding Standards

- Follow the existing code style (Dart lints are enforced via `flutter analyze`)
- No hardcoded colours — use `AppColors` tokens
- No hardcoded strings visible to users — keep them in the widget tree, not in service/repository layers
- Animation durations use `kSpring = Cubic(0.16, 1.0, 0.3, 1.0)` from `lib/core/animations/animations.dart`
- All async methods that touch the widget tree must check `mounted` before `setState` or `context` calls
- New `Prompt` paths are `List<String>` encoded via `PromptRepository.encodePath()` — never store raw strings

---

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add quick add to overlay bottom sheet
fix: correct bottom sheet pop context in overlay
docs: update README installation steps
chore: bump drift to 2.23.0
test: add round-trip import/export test
```

Types: `feat` `fix` `docs` `chore` `test` `refactor` `perf`

---

## Sharing Prompt Packs

One of the best contributions is high-quality prompt packs. Packs use the [APM `.prompt.md` format](https://microsoft.github.io/apm/producer/author-primitives/prompts/) and are distributed as `.zip` files.

A minimal pack looks like:

```
my-pack.zip
├── apm.yml
└── .apm/
    └── prompts/
        └── my-prompt.prompt.md
```

```yaml
# apm.yml
name: my-pack
version: 1.0.0
description: A curated set of prompts for ...
type: prompts
```

```markdown
---
description: Summarize concisely
input:
  - text: "Text to summarize"
x-loadstash-path: [Writing, Edit]
x-loadstash-tags: [writing]
---

Summarize the following in 3 bullet points:

${input:text}
```

Open an issue with the **Prompt Pack** label to share your pack with the community.
