# Loadstash — v1 Build Spec

A local-first Android app that lets you insert saved and curated AI prompts into **any** text field, from inside any app, via Android's text-selection menu. The library and your custom prompts live on-device; nothing leaves the phone.

---

## 1. What it is and why it exists

**One-line concept:** Loadstash — your prompts, curated and your own, usable in any app, on any AI, inserted in seconds.

- A real prompt **library** built for reuse, not recent-copy history.
- **`{{variables}}`** you fill in at insert time.
- **App-aware ranking** (your Claude prompts surface in Claude, your ChatGPT prompts in ChatGPT).
- Curated, model-tagged starter content so the app is useful on first open.

---

## 2. The core mechanism: ACTION_PROCESS_TEXT

This is the legitimate, low-permission way to put the app in the long-press menu. **No accessibility service, no draw-over-apps permission in v1.**

**Reuse before you build.** Before writing any native code, check pub.dev for a *currently maintained* Flutter package that already wires up `PROCESS_TEXT` (e.g. something like `text_selection_intent`). If one exists and is genuinely maintained — recent commits, sound issues, supports current Android/Flutter — use it. **Only if there is no maintained package** do you write the thin Kotlin native bridge yourself. Don't hand-build what you can adopt; revisit this if the package goes stale later.

- Register an `intent-filter` for `android.intent.action.PROCESS_TEXT` on a dedicated activity, with `android:label` set to the menu name users will see.
- When a user **selects text in any app** and taps your name in the floating selection toolbar, Android launches your activity and passes the selected text via `EXTRA_PROCESS_TEXT`.
- `EXTRA_PROCESS_TEXT_READONLY` tells you whether the field is editable. If editable, you may **return replacement text** (`setResult` with the assembled prompt), which Android drops back into the field.
- The activity is styled as a **translucent bottom sheet** so the host app stays visible behind it. This *is* the "overlay" in v1 — it only looks like an overlay; it's really a transparent screen with zero special permissions.

**The one hard constraint:** PROCESS_TEXT only appears when text is **selected**. There is no empty-field trigger. So v1 is designed around *having a selection*, with two primary flows:

1. **Wrap selection (best fit).** User highlights rough text, picks a template, and it wraps their text: `"rewrite this professionally: <selected text>"`. This is the most natural use of the constraint.
2. **Type-then-trigger.** For a near-empty box: type a throwaway character (or a short trigger like `//`), select it, tap the app, pick a prompt; the returned text *replaces* that character.

The draw-over **floating bubble** (true empty-field trigger) needs a foreground service + overlay permission. **Deferred to v2** — only build it if testing proves the empty-field case is a real blocker.

---

## 3. The overlay (translucent activity) — behavior

**Job: get in, pick, get out.** Speed is its only mandate.

Triggered by: select text → tap app name in the long-press menu.

**Layout (top to bottom):**
- **Search bar** — instant fuzzy search over the whole library. Primary action once the library is non-trivial.
- **Recently / most-used** — the default view before searching. App-aware (see §9). This is the "it learns me" surface.
- **Pinned prompts** — user's hand-chosen favorites; always shown, always override ranking.
- **Filter chips** — All / by model. Light, optional.

**On tapping a prompt:**
- **No variables** → assembled and inserted immediately; overlay closes. Target: under ~3 seconds end-to-end.
- **Has variables** → a small fill-in sheet slides up (one field per *unique* variable) → Insert assembles the final text and returns it.

**Two overlay-only actions (cheap, because the selected text is already in hand):**
- **Save selection as prompt** — quick-save the highlighted text into the library (full editing happens later in the app).
- **Wrap selection** — pick a template that embeds the selected text.

---

## 4. The main app — screens

The app is the **workshop** (calm-moment management); the overlay is the **launcher** (in-task use).

1. **Library (home).** Two sections: *Your Prompts* and the bundled *Starter Library*. Full search, folder/tag navigation, pin toggles.
2. **Prompt editor.** Create/edit: title, body with a `{{variable}}` insert helper, folder, tags, model tags, pin toggle, and a **live preview** showing the variable fields as they'll appear in the overlay. Chaining/stacking is assembled here too.
3. **Organization.** Folder and tag management — rename, move, bulk-organize. Essential past ~50 prompts.
4. **Settings.** Local-first/privacy statement, theme, import/export, model-tag management, overlay preferences.
5. **Onboarding (first run).** Not optional. PROCESS_TEXT is invisible, so the first launch must (a) **show the gesture** with a short animation (select → tap app name → pick prompt), and (b) **seed the starter library** so the app isn't empty. A confusing first run is the single most likely week-one uninstall cause.

---

## 5. Overlay vs app: what lives where

**The governing principle.** The overlay is for *using* prompts in the middle of a task, inside someone else's app. The app is for *managing* prompts in a calm moment. Every placement decision follows from this: if something requires the user to stop, type, or think, it belongs in the app. If it has to be instant and benefits from the live selection/context, it belongs in the overlay.

**Decision rule for any future feature:** *Does the user invoke this while doing something else, or while tending their collection?* In-task → overlay. Tending the collection, or anything requiring typing or judgment → app. When genuinely unsure, default to the app — the overlay's value is destroyed by clutter far faster than the app's is.

### In the overlay — and why each earns its place
- **Search + browse (recents, pinned, model filter)** — the whole point of invoking it is to *find and insert* a prompt fast. These are read-and-tap actions, zero typing beyond the search query.
- **Variable fill-in** — this *executes* here because it can only happen at insert time, against the real context. (The variables themselves were *defined* in the app.)
- **Save selection as prompt** — lives here only because the overlay already has the selected text in hand; capturing it is one tap. Editing/organizing that captured prompt happens later, in the app.
- **Wrap selection** — same reason: it needs the live selection, which only exists at overlay time.

Everything in the overlay shares one trait: it's fast, it's tap-driven, and it either needs the live selection or needs to be reachable mid-task.

### In the app — and why it's not in the overlay
- **Creating / editing prompts** — requires typing and thought; a calm-moment task. Putting an editor in the overlay would turn a 3-second launcher into a workspace.
- **Defining variables, defaults, model tags** — setup decisions made once, not per-insert.
- **Building chains/stacks** — composing role + task + format is deliberate authoring; the overlay just inserts the finished stack as one unit.
- **Folder / tag management, bulk organizing** — housekeeping, only relevant once the library grows.
- **Settings, import/export, privacy controls** — configuration, done rarely.
- **Onboarding** — first-run teaching; has no place in a mid-task launcher.

### Deliberately NOT in the overlay (state this as a rule for yourself)
Editing, organizing, configuring, onboarding, and bulk actions are **banned** from the overlay. The instant you're tempted to add one, you're rebuilding the app inside the launcher and breaking its only job. The overlay stays a launcher; the app stays the workshop.

### Shared across both (but doing different jobs)
- **The prompt data** is one local store; both surfaces read it.
- **Search exists in both** — but in the overlay it's a fast fuzzy *pick*, while in the app it's part of full *management* (alongside folders, tags, edit). Same input box, different intent.

### Quick reference

| Feature | Defined / managed in | Executed / surfaced in |
|---|---|---|
| `{{variables}}` | App editor (+ auto-detect on save) | Overlay (fill-in + insert) |
| Chaining / stacking | App editor (saved as one unit) | Overlay (inserted as one) |
| Recently / most-used | tracked silently | Overlay (app-aware ranking) |
| Folders / tags | App | Search in **both** |
| Per-model tagging | App | Overlay (filter chips) |
| Import / export | App (Settings) | — |
| Save selection as prompt | edited later in App | Overlay (capture) |
| Onboarding | App (first run) | — |

---

## 6. End-to-end user flows

Concrete walkthroughs showing how the overlay and app hand off to each other.

### Flow A — First run (onboarding)
1. User installs and opens the app.
2. Onboarding **shows the gesture** with a short animation: select text → tap the app's name in the long-press menu → pick a prompt → it's inserted.
3. The **starter library is seeded** automatically, so the library isn't empty.
4. User is nudged to try it once inside the app on a sample field, so the gesture clicks before they're out in the wild.

*Why it matters:* the gesture is invisible; without this, most users never discover how to trigger the tool and churn in week one.

### Flow B — Everyday insert, no variables (in ChatGPT)
1. User is in the ChatGPT app, taps the message box, types a throwaway character, and selects it (type-then-trigger).
2. Long-press menu appears → user taps the app's name.
3. The translucent overlay slides up over ChatGPT, defaulting to **recently / most-used — ranked for ChatGPT specifically** (their ChatGPT prompts on top).
4. User taps a prompt with no variables → it's assembled and dropped into the box, overlay closes. Under ~3 seconds.

### Flow C — Wrap selection with variables (in Claude)
1. User has drafted a rough paragraph in Claude's input and wants it rewritten.
2. They **select the paragraph** → long-press menu → tap the app.
3. Overlay opens; they search "rewrite" and tap a template like `Rewrite this in {{tone}} for {{audience}}: <selected text>`.
4. A **fill-in sheet** slides up with two fields — `tone` and `audience` (deduped, asked once each).
5. They fill `tone = formal`, `audience = a client`, tap **Insert**.
6. The overlay returns the assembled prompt with their paragraph wrapped inside, and Claude's field now holds the finished text.

### Flow D — Capture a prompt in the wild, refine later
1. User spots a great prompt in a Reddit thread or a chat.
2. They **select it** → long-press menu → tap the app → **Save selection as prompt**. One tap; back to what they were doing.
3. Later, in a calm moment, they open the **app**, find the captured prompt under *Your Prompts*, and the editor flags **"Detected 1 variable: topic"** because the saved text contained `{{topic}}`.
4. They give it a title, drop it in a folder, add a `model tag`, and pin it. It's now first-class library content.

*This is the overlay→app handoff in miniature: capture fast in-task, refine deliberately later.*

### Flow E — Calm-moment authoring (app only)
1. User opens the app, goes to the **editor**, and builds a **chained prompt**: a role block + a task block + a format block saved as one unit.
2. They insert `{{variables}}` via the helper, see them appear in the **live preview** exactly as the overlay will show them.
3. They tag it for image-gen models and pin it.
4. Next time they're in an image tool, that stack is one tap away in the overlay — inserted as a single finished prompt.

---

## 7. Design direction — dark-first, minimal, polished

**The feel.** Calm and quiet, like ZenNotes — restraint over decoration, content over chrome — with the soft, card-based polish of Sequel. Dark is the *designed* default (light is offered but dark is the hero). The overlay especially must feel weightless: it appears over someone else's app, so it has to read as a light, premium layer, never a heavy window. Nothing shouts. One accent, used sparingly.

*Note: the palette below is designed in the spirit of those references, not copied from them — tune the exact values once you see it on a real screen.*

### Color tokens (dark — default)
| Token | Value | Use |
|---|---|---|
| `bg.base` | `#0E0F12` | App background (near-black, slight blue-grey — never pure `#000`) |
| `surface.1` | `#16181D` | Cards, prompt rows |
| `surface.2` | `#1B1E24` | Overlay bottom sheet, raised elements |
| `border.hairline` | `rgba(255,255,255,0.07)` | Separators, card edges (hairlines, not heavy lines) |
| `text.primary` | `#ECEEF2` | Titles, prompt text (soft white, never `#FFF`) |
| `text.secondary` | `#9BA0AA` | Labels, metadata |
| `text.tertiary` | `#686D78` | Placeholders, disabled |
| `accent` | `#8B7DF6` | Primary actions, active state (a muted periwinkle — deliberately *not* generic AI-blue) |
| `accent.tint` | `rgba(139,125,246,0.14)` | `{{variable}}` highlight background, selected chip fill |
| `confirm` | `#5BC58F` | Insert/save success only (used very sparingly) |

### Color tokens (light — secondary)
`bg.base` `#FAFAF8` (warm off-white) · `surface` `#FFFFFF` · `text.primary` `#1A1B1E` · `border` `rgba(0,0,0,0.08)` · `accent` `#6F5EE0` (slightly deeper for contrast).

### Model-tag colors (subtle, Sequel-style coding)
Used only as small dots/chips, muted, never as fills: Claude `#C98A5E` (clay) · ChatGPT `#4FB58B` (teal-green) · Gemini `#5B8DEF` (blue) · Local/other `#B98BD4` (muted purple). These give the per-model filter a quiet, legible color language without turning the UI into confetti.

### Typography
- **UI:** Inter (or the platform sans), weights **400 / 500**, with 600 reserved for screen titles only. Avoid heavy bolding — restraint reads as polish.
- **Prompt bodies + `{{variables}}` + key hints:** a **monospace** (JetBrains Mono / IBM Plex Mono). Prompts are text you edit, and mono makes `{{tokens}}` unmistakable — this is also a nod to ZenNotes' mono accents.
- Comfortable sizing (≈16 body, 13 secondary), generous line-height (≈1.5 prose, 1.3 UI).

### Shape, spacing, depth
- **8pt grid** (4pt for fine alignment); favor breathing room over density.
- **Radii:** rows/cards `14–16`, bottom-sheet top corners `22–24`, chips full-pill, buttons `12`.
- **Depth via surface lightness, not shadows.** Dark UIs convey elevation by stepping `surface.1 → surface.2`, with at most one very soft shadow on the overlay sheet. No heavy drop shadows.
- Prefer **spacing and cards over dividers**; when a line is needed, use `border.hairline`.

### The overlay (the hero surface — get this perfect)
- Bottom sheet with rounded top corners and a subtle **drag handle**; a dimmed + lightly **blurred scrim** behind so the host app is felt but de-emphasized.
- **Search auto-focused** on open. Recents/pinned render as soft `surface.1` rows; the model filter is a quiet pill row.
- **Variable fill-in:** show a preview line where each `{{token}}` is an `accent.tint` pill, so the user sees exactly what they're filling.
- **Insert button:** full-width filled `accent`, with a light **haptic** + ~120ms confirmation on success, then dismiss.
- **Weightless motion:** the sheet slides + fades up in **~220ms** ease-out / gentle spring. No per-row animation (speed beats flourish). It must clear the cold-start budget in §12.

### Motion & system
- Keep motion subtle and fast; **respect "reduce motion."**
- Follow the system light/dark setting by default, but dark is the designed reference.

### Iconography & wordmark
- Minimal line icons, ~1.5px stroke, monochrome with `accent` only for the active state.
- Wordmark: **loadstash** lowercase, in the mono or a refined sans, with an optional subtle weight/colour break between *load* and *stash* to teach the fusion. Understated, never loud.

### Empty & first-run states
- Design the empty states (no bare lists). Onboarding lives in the same calm dark aesthetic; render the gesture animation cleanly rather than as a stock tutorial.

### "Looks expensive" checklist
- Never pure `#000` or `#FFF`.
- One accent, used only for primary action + active state.
- Hairlines, not heavy borders; consistent radii; optical (not just metric) alignment.
- Tactile feedback (haptics) on insert and save.
- Tight, legible type with bold used sparingly.

---

## 8. Variables — detailed spec

**Auto-detection.** On save (from the overlay's "save selection" *or* the app editor), scan the body for the `{{...}}` pattern. Each match registers as a variable for that prompt; next insert triggers the fill-in sheet.

**Rules to decide now (they bite later):**
- **Dedupe by name.** `Rewrite in {{tone}} for {{audience}}, keep it {{tone}}` = **two** fields; `tone` is asked once and substituted everywhere it appears.
- **Malformed input is literal.** `{{tone}`, `{{ }}`, nested braces → treated as plain text, never a phantom field.
- **Confirm on save.** Show "Detected 2 variables: tone, audience" so a typo'd `{{tonne}}` is caught before it becomes a permanent weird field. Silent wrong guesses are worse than no detection.

**Data model (design rich now, ship simple).** Store each variable as an object, not a scraped string:

```
Variable {
  name: String          // "tone"
  type: text | select   // v1 = text only; select reserved
  default: String?       // optional
  options: [String]?     // for future dropdowns
}
```

v1 uses free-text only, but modeling it this way means "tone = formal / casual / playful" dropdowns drop in later for free. Retrofitting this is painful.

---

## 9. App-aware ranking — detailed spec

The standout differentiator, and nearly free to build: **the PROCESS_TEXT intent tells you the calling package** (`com.openai.chatgpt`, `com.anthropic.claude`, etc.). Most prompt tools ignore this entirely.

**Track usage per prompt, per app:** a small `{ promptId, packageName, count, lastUsedAt }` record.

**Blend, don't hard-filter.** Rank by a score that **weights the current app's usage heavily but still factors global usage + recency**. This avoids the cold-start void — a brand-new app context still shows your genuinely-most-used prompts instead of an empty list. As app-specific history accumulates, it naturally dominates: Claude prompts rise in Claude, ChatGPT prompts rise in ChatGPT, with zero setup from the user.

**Guardrails:**
- **Favor stability.** Don't let one or two uses make a prompt leap to the top — gradual shifts keep the list predictable and trusted.
- **Keep it explainable, keep manual control.** **Pinned always overrides** the algorithm. Users want a smart default *and* the ability to overrule it.
- **All local.** This behavioral data never leaves the device — and say so in the settings copy, because "it learns your habits per app" reads as surveillance until you add "…and never leaves your phone."

---

## 10. Starter library & sourcing rules

**What ships:** a curated starter set (a few hundred genuinely good prompts) bundled as local data, organized by task (coding, writing, study, image-gen, …). Works offline; fits the privacy story; solves cold-start.
---

## 11. Per-model handling

**v1 approach (cheap, no AI):** tag each prompt with the model(s) it's tuned for; let users filter. That's the whole feature for v1.

**The patterns worth tagging around** (maintain as *editable data*, never hardcoded — this advice decays):
- **Claude** — likes structure: XML-style tags, explicit roles, detailed instructions.
- **GPT** — forgiving of loose phrasing, likes examples; newer reasoning models do *worse* when told to "think step by step" (they already do).
- **Gemini** — concise, direct instructions; strong with very large context.
- **Local models** (Llama, Mistral…) — most sensitive; often need the model's specific chat template.
- **Image/video models** (Midjourney, SD, Sora…) — **biggest leverage.** Real learnable syntax (weights, parameters, subject/style/lighting ordering). The naive-vs-optimized difference is *visible*, which makes this the most compelling content for the library.
---

## 12. Tech stack (Flutter)

Flutter is a good fit: one codebase, fast UI work, ideal for the polished overlay/editor. But two features are Android OS integrations, not standard widgets — handle them via **platform channels** + a little Kotlin/manifest.

- **Flutter (the bulk):** overlay bottom sheet, library browser, prompt editor, variable fill-in, settings. Local storage via `drift`/`sqflite` (SQLite) or local JSON.
- **Native glue (thin):**
  - PROCESS_TEXT: per §2, **reuse a maintained Flutter package if one exists** (manifest `intent-filter` + intent handling); only fall back to your own Kotlin if none is maintained.
  - Returning the chosen prompt: pass the assembled text back over the channel and `setResult` so Android inserts it.
  - Reading the calling package name (for §9) comes off the same intent.
- **Watch cold-start speed.** This launches from a text-selection tap and must pop instantly. A heavy startup on a quick-insert tool is an uninstall trigger — profile launch time early.
- **Floating bubble** = native foreground service + overlay permission → **v2, only if needed.**

**Sketch data model:**
```
Prompt { id, title, body, folder, tags[], modelTags[], pinned,
         variables: [Variable], createdAt, updatedAt }
Variable { name, type, default?, options[]? }
UsageStat { promptId, packageName, count, lastUsedAt }
Folder { id, name }   Tag { id, name }
```
