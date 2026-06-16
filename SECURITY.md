# Security Policy

Loadstash is a **local-first Android app**: your prompt library and usage data live on your device, and v1 has no backend or account system. Even so, the app handles personal text and can request sensitive Android permissions, so security and privacy are taken seriously and good-faith reports are welcome.

## Reporting a vulnerability

Please report security issues **privately**. Do **not** open a public GitHub issue, pull request, or discussion for anything security-sensitive.

- **Email:** agrawalskushal@gmail.com
- **Subject:** start it with `[Loadstash Security]` so it can be triaged quickly.

If you can, include:

- A clear description of the issue and its potential impact.
- Steps to reproduce — a proof-of-concept, sample input, or screenshots all help.
- The app version / build, your Android version, and device (if relevant).
- Any suggested fix or mitigation you may have.

You're welcome to encrypt sensitive details — mention it in your first email and a key will be arranged.

## What to expect

This is a small project, so timelines are best-effort but genuinely honored:

- **Acknowledgement:** within 5 business days.
- **Initial assessment:** within 14 days, with a severity estimate and next steps.
- **Fix & disclosure:** you'll be kept updated, and the aim is to ship a fix before any public disclosure.

## Coordinated disclosure

Please give a reasonable window to fix the issue before disclosing it publicly — typically up to 90 days from the report, or sooner once a fix ships. Timing can be coordinated, and credit is offered (see below).

## Scope

Particularly relevant for Loadstash:

- The Android app and how it stores and handles your prompt data and usage history.
- The sensitive permissions it can request (**Accessibility**, **display-over-other-apps**) and the text it can read or insert through them.
- Local data storage and the **import/export of files** (e.g. a malicious or malformed YAML import).
- Any future networked features (community packs, sync) once they ship.

Generally **out of scope**:

- Vulnerabilities in third-party dependencies, Android itself, or other apps (please report those upstream).
- Issues requiring a rooted device, physical access, or an already-compromised OS.
- Social engineering, phishing, or attacks against the maintainer's accounts.
- Best-practice suggestions with no demonstrable security impact.

## Supported versions

Until the first stable release, only the **latest release** and the **`main`** branch receive security fixes.

| Version | Supported |
|---|---|
| Latest release / `main` | ✅ |
| Older / pre-release builds | ❌ |

## Recognition

Loadstash does not run a paid bug-bounty program. For valid, responsibly disclosed reports, credit is gladly given by name or handle in the release notes or a security acknowledgements list — just say how you'd like to be credited, or if you'd prefer to remain anonymous.

## Safe harbor

Security research conducted in good faith — respecting user privacy, avoiding data destruction or disruption, and following this policy — is considered authorized, and no legal action will be pursued or supported against researchers acting in good faith. If you're unsure whether something is in scope, ask first at the email above.
