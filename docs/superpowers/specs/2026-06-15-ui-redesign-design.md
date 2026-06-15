# Loadstash UI Redesign — Design Spec
## (Part B: Library + Folders · Part C: Custom Tags · UI Polish + Onboarding)

**Source of truth:** `mockups/Loadstash.dc.html` — interactive prototype with gallery view.

---

## 1. Color Tokens

### Add to AppColors (new)
| Token | Dart const | Use |
|---|---|---|
| `hair2` | `Color(0x0DFFFFFF)` | Subtler hairline (prompt body bg, 5% white) |
| `accentText` | `Color(0xFFB9AEFF)` | Accent text/icons on dark surfaces |
| `accentDim` | `Color(0x4D8B7DF6)` | Accent borders — active inputs, sheet outlines (30%) |
| `successTint` | `Color(0x215BC58F)` | Success bg — filled variable pills, all-set card (13%) |

### Update model colors
| Model | Old | New |
|---|---|---|
| Claude | `#C98A5E` | `#D97757` |
| ChatGPT | `#4FB58B` | `#10A37F` |
| Gemini | `#5B8DEF` | `#5B9CF6` |
| Local | `#B98BD4` | `#8A909C` |

---

## 2. Animation System

### Keyframe animations (reusable widgets)
| Name | Behaviour | Duration | Flutter |
|---|---|---|---|
| `BobAnimation` | translateY 0↔-5dp | 3s ease-in-out ∞ | `AnimationController` + `Curves.easeInOut` + `Transform.translate` |
| `RingAnimation` | scale 1→2.2 + opacity 0.55→0 | 2.6s ease-out ∞ | `ScaleTransition` + `FadeTransition`, loop |
| `FadeUpAnimation` | opacity 0→1 + translateY 9→0dp | 280ms `Cubic(0.16,1,0.3,1)` | `FadeTransition` + `SlideTransition` |
| `CaretAnimation` | opacity toggle step | 1.1s step (550ms on/off) | `AnimationController` + `Tween<double>(0,1)`, step |
| `PopAnimation` | scale 0.6→1.06→1.0 + fade | 380ms | `Curves.elasticOut` |

### Spring easing (used everywhere)
`Cubic(0.16, 1.0, 0.3, 1.0)` — fast-out spring. Flutter constant: `_kSpring`.

Used on:
- Bottom sheet slide-up: 360ms
- Keyboard demo slide: 420ms
- Sheet panel switch: 450ms
- Toggle switch thumb: 220ms

### Specific animations per component
- **Onboarding dots**: active dot `AnimatedContainer` width 7→20dp, 300ms
- **Onboarding chat bubbles**: staggered `FadeUpAnimation` at 0ms / 500ms / 1100ms per step
- **Step 4 demo card**: auto-cycles 6 phases every 1500ms with `Timer.periodic`
- **Bubble drag**: `Transform.scale(1.08)` + `Transform.rotate(-4°)` on pointer down
- **Scrim**: `AnimatedOpacity` 0→0.5, 300ms ease
- **Bottom sheet scrim**: same as above

---

## 3. Data Model Changes

### Prompts table
Remove `folderId` (integer FK to Folders). Add:
- `path TEXT` — JSON-encoded string array e.g. `'["Writing","Email","Cold"]'`. Empty array = library root.
- `searchTags TEXT` — JSON-encoded string array e.g. `'["work","sales"]'`. Default `'[]'`.

Keep `modelTags TEXT` (unchanged, comma-separated).

### Folders table
**Delete entirely.** Folders are derived from prompt paths at runtime — no stored folder entities. The `FolderDao` and `folder_dao.dart` are removed.

### Migration
Schema version 1→2. In `MigrationStrategy`:
```dart
onUpgrade: (m, from, to) async {
  if (from < 2) {
    // add path and searchTags columns
    await m.addColumn(prompts, prompts.path);
    await m.addColumn(prompts, prompts.searchTags);
    // migrate existing folderId → empty path (can't recover old folder names)
  }
}
```

---

## 4. Screen Designs

### 4.1 Onboarding (5 steps)

**Step 1 — Welcome**
Full-height chat layout. Three Loadstash bubbles fade-up in sequence (staggered). Bottom: "Get started" filled button with chevron icon.

Header: avatar icon (accent tint 30×30 rounded square) + "Loadstash" + "Setup · about 20 seconds" subtitle. "Skip" text button top-right (steps 1–4 only).

Progress dots: 5 dots, active = 20dp wide pill, past = 7dp accent dim, future = 7dp 12% white. `AnimatedContainer` transitions.

**Step 2 — Turn on launcher**
Chat bubble: "First, turn on the launcher."
Toggle card (card bg, accent border when on): Sparkle icon + "Loadstash launcher" title + "Off/On" status + `ToggleSwitch`.
Privacy note below: shield icon (success green) + "Works entirely on your device..." text.
Button disabled and 50% opacity until toggle on.

**Step 3 — Permissions**
Chat bubble: "Now grant two permissions..."
Two permission rows (card with accent-border when granted):
- Accessibility: accessibility icon, title, description, Grant button / "Granted" + check
- Display over other apps: layers icon, same structure

Both granted → Continue button enables.

**Step 4 — How it works (animated demo card)**
Chat bubble: "Here's how it works — watch:"
Demo card (rounded 18dp border, dark bg) auto-cycles 6 phases via `Timer.periodic(1500ms)`:
0. Keyboard up, compose field with caret
1. Bubble appears at edge (with ring pulse)
2. Sheet slides up — prompt list
3. Sheet — prompt list with one highlighted
4. Sheet — fill in variable (topic input + OK button)
5. Keyboard up, compose field filled with inserted text

Caption strip at bottom: step number chip + caption text.

**Step 5 — All set**
Centred layout. Green check icon in success-tint circle (72×72, 22dp radius). "You're all set" title. Description text. "Open Loadstash" button with sparkle icon.

---

### 4.2 Library Screen

**Root view:**
AppBar: "Library" large title (25sp, fontWeight 600, tracking -0.02em) + `+` icon button (new folder).
Search bar below title: card bg, hair border (accent dim when active), search icon + input + clear X.

**Pinned section** (root only, when pinned prompts exist):
Section label "PINNED". Horizontal `ListView` (scrollable, edge-to-edge with -18dp margin + 18dp padding, hides scrollbar). Cards are 210dp wide:
- Pin icon top-right (accent)
- Title (13.5sp bold)
- Mono preview (34dp tall, clipped)
- Model dots row at bottom
Tap → Prompt detail screen.

**Folders section:**
Section label "FOLDERS" / "SUBFOLDERS". Vertical list of folder rows:
- 36×36 accent-tint rounded square icon + folder icon (accentText)
- Name (14.5sp 500) + "{n} prompts" subtitle
- Chevron right
Tap → navigate into folder (push new path).

**Prompts section:**
Section label "ALL PROMPTS" / "PROMPTS HERE". Vertical list of prompt cards (see §4.5).

**Inside a folder:**
AppBar replaced with: back arrow button (34×34 card-bg rounded) + folder name (19sp 600) + path breadcrumb below + `+` icon. Back arrow pops path.

**New folder bottom sheet** (maxH 60%):
"New folder" title. Location label. Input field with folder icon + cursor animation. "Create folder" primary button.

**Empty state:** Centre-aligned text "No prompts here yet."

---

### 4.3 Prompt Detail Screen

Full screen, replaces the current tap-to-edit behaviour.

Header: "← Library" back text button + Pin toggle button (accent tint when pinned, accent border).

Body (scrollable):
- Title (23sp 600, tracking -0.02em)
- Path breadcrumb (`Library › Writing › Email`) + "Move" ghost pill button (folder icon)
- Models section: model chips with colour dot + label
- Search tags section: `#tag` dashed pill chips
- Prompt section: card with full mono body, variable pills highlighted. Below: "{n} variables filled in when used" if vars exist.

Bottom action bar (border top): Edit ghost button (flex 0) + Copy to clipboard primary button (flex 1).

Move to folder → bottom sheet with folder picker list.

---

### 4.4 Editor Screen (updated)

Nav: Cancel text | "New prompt" / "Edit prompt" title | Save text (accent).

Fields (scrollable):
1. **Title**: input field
2. **Prompt**: mono textarea (min 128dp), JetBrains Mono
3. **Variables**: auto-detected pills (accent tint) + manual add input + "Add" button. Empty state: hint text.
4. **Folder**: tappable row → folder picker bottom sheet
5. **Models**: toggle chip row (colour dot + label + check when selected)
6. **Search tags**: existing tag chips (removable with ×) + add tag input + Add button

Bottom: primary "Create prompt" / "Save changes" button.

---

### 4.5 Prompt Card (in library lists)

```
┌─────────────────────────────────────────────┐
│ Title                       ● ● [pin icon]  │
│ ┌─────────────────────────────────────────┐ │
│ │ mono body preview (1 line, clipped)     │ │  ← hair2 bg
│ └─────────────────────────────────────────┘ │
│ Library › Writing › Email        #work #dev │
└─────────────────────────────────────────────┘
```
- Card bg surface1, 15dp radius, hair border
- Model dots: 7dp circles, model colours, right-aligned top
- Pin icon: 13dp accent, shown only when pinned
- Mono preview: accent tint bg, hair2 border, 9dp radius, 11.5sp
- Path crumb: t2 colour, 11sp, `›` separator in t3
- Tags: dashed pill `#tag` chips, t2 text

---

### 4.6 Settings Screen (complete redesign)

Title "Settings" (25sp 600).

**Launcher card** (accent border when on, hair border when off):
Sparkle icon (42×42 accent-tint rounded) + "Loadstash launcher" + "On · bubble active when typing" / "Off" status + `ToggleSwitch`.
Divider. Below: permission status line + "Details →" accent text button → Access explainer bottom sheet.
Privacy note: shield icon + "Local-first. Everything stays on this device."

**Sections (card-style groups with internal dividers):**

Appearance:
- Theme: Light/Dark toggle (segmented control style, accent tint active)

Your library:
- Import from YAML → import prompt
- Export to YAML → export
- Default save location → folder picker
- Manage tags → Tags screen

Community:
- Browse community packs → "Coming soon" badge, dimmed
- Submit a pack → "Coming soon" badge, dimmed

Footer: "Loadstash v1.0 · made for Android" centred, t3.

---

### 4.7 Tags Screen (new)

Back "← Settings" nav.
Title "Tags" (23sp 600).
Subtitle: "Two ways to organise..."

**Search tags section:**
Hash icon + "Search tags" title. Description. Wrap of `#tag` dashed pill chips. "New tag" dashed accent button.

Divider.

**Model tags section:**
Model dot row + "Model tags" title. Description.
Vertical list of model tag rows (card bg, 13dp radius):
- 12dp colour dot
- Label + hex code (mono, t3)
- "prefilled" or "custom" badge pill
"Add model tag" dashed full-width button.

---

### 4.8 Overlay Screen (bubble mode — updated)

Picker sheet:
- Search bar + `+` (Quick add) button inline
- Model filter chips horizontal scroll (All, Claude, ChatGPT, Gemini, Local — colour dots)
- Sections: Pinned, Most used — compact rows (title + model dots + chevron)

Quick add sub-sheet:
- Back chevron + "Quick add" + "Save" text
- Mono textarea
- Variable detection count
- Pin toggle row
- Model tag chips
- "Saves to [folder]" info row
- "Save prompt" primary button

Variables sheet: existing design (already implemented).

---

## 5. Scope & Build Order

1. **Task 1:** Color tokens update (AppColors — new tokens + model colors)
2. **Task 2:** Animation primitives (reusable widget library: BobAnimation, RingAnimation, FadeUpWidget, PopWidget, spring curve constant)
3. **Task 3:** Data model migration (path + searchTags columns, remove Folders table, schema v2)
4. **Task 4:** PromptRepository update (path-based folder queries, searchTags CRUD)
5. **Task 5:** Library screen redesign (pinned row, folder browser, breadcrumb nav, search)
6. **Task 6:** Prompt detail screen (new screen on card tap)
7. **Task 7:** Editor screen update (folder picker sheet, tags, cleaner layout)
8. **Task 8:** Onboarding redesign (5 steps, chat bubbles, animated demo card)
9. **Task 9:** Settings redesign + Tags screen
10. **Task 10:** Overlay picker updates (model filter chips, quick add)
11. **Task 11:** Build verification + flutter test
