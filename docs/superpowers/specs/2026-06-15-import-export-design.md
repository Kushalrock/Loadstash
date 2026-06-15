# Import / Export Design Spec
## APM-Compatible ZIP Import + Export

**Source standard:** [APM Agent Package Manager — Prompts primitive](https://microsoft.github.io/apm/producer/author-primitives/prompts/)

---

## 1. ZIP Package Format

### Directory structure
```
my-prompt-pack.zip
├── apm.yml                              # Required package manifest
└── .apm/
    └── prompts/
        ├── cold-outreach.prompt.md      # One file per prompt
        ├── code-review.prompt.md
        └── rewrite-professionally.prompt.md
```

### `apm.yml` (minimal required)
```yaml
name: my-writing-prompts
version: 1.0.0
description: A curated collection of writing prompts
author: username
type: prompts
```

Required fields: `name`, `version`. `type: prompts` is optional but recommended.

### `.prompt.md` file format
```markdown
---
description: Cold outreach email
input:
  - name: "Recipient's first name"
  - company: "Company name"
  - product: "What you're pitching"
  - length: "Max word count e.g. 120"
model: claude
x-loadstash-path: [Writing, Email, Cold]
x-loadstash-tags: [work, sales]
x-loadstash-pinned: false
x-loadstash-model-tags: [claude, chatgpt]
---

Write a cold email to ${input:name} at ${input:company} about ${input:product}. Keep it under ${input:length} words — friendly, specific, no fluff.
```

### Frontmatter field mapping

| `.prompt.md` field | Loadstash field | Notes |
|---|---|---|
| `description` | `title` | Required by APM |
| `input[].key` | variable names | Each key becomes a `{{key}}` variable internally |
| `input[].value` | variable hint/placeholder | Shown in fill-in sheet |
| `model` | first `modelTags` entry | APM supports one model; use `x-loadstash-model-tags` for full list |
| `x-loadstash-path` | `path` (List<String>) | e.g. `[Writing, Email, Cold]` |
| `x-loadstash-tags` | `searchTags` (List<String>) | User search tags |
| `x-loadstash-pinned` | `pinned` (bool) | Default false if absent |
| `x-loadstash-model-tags` | `modelTags` (comma-joined) | Overrides `model:` when present |

### Variable rules (APM spec)
- Variable syntax in body: `${input:name}`
- Name pattern: `[A-Za-z][\w-]{0,63}`
- Internally stored as `{{name}}` — converted on import/export
- No required/optional distinction in APM — communicate via description text
- No default values in APM spec — describe them in the input description

---

## 2. Import Flow

### Trigger
Settings screen → "Import from ZIP" → file picker (`.zip` files only)

### Validation
1. ZIP must contain `apm.yml` at root — reject with error if missing
2. ZIP must contain at least one `.prompt.md` in `.apm/prompts/` — reject if none found
3. Invalid YAML in any file → skip that file, show warning in summary

### Parsing each `.prompt.md`
1. Split file on `---` delimiter to separate YAML frontmatter from body
2. Parse frontmatter YAML
3. Extract `description` → title
4. Extract `input:` list → variable names + hints
5. Extract `model:` → modelTags fallback (if no `x-loadstash-model-tags`)
6. Extract `x-loadstash-*` fields → path, tags, pinned, full model tags
7. Body: text after second `---`, trimmed
8. Convert `${input:name}` → `{{name}}` in body (for internal storage + fill-in sheet)

### Folder assignment for path-less prompts
If any `.prompt.md` has no `x-loadstash-path:` field (i.e. pure APM prompt from another tool):
- Show `FolderAssignmentSheet` — a `FolderPickerSheet` variant with title "Where should these prompts go?"
- User picks a destination folder
- All path-less prompts from this import go into that folder
- User can edit them individually afterward

### Success summary
Bottom-sheet toast: **"Imported 8 prompts from writing-pack v1.0.0"**
(pack name + version from `apm.yml`)

---

## 3. Export Flow

### Trigger
Settings screen → "Export to ZIP" → scope choice sheet

### Scope choice sheet
Three-option bottom sheet:
- **All prompts** — everything in the library
- **Your prompts** — only `isStarter: false` prompts
- **Starter library** — only `isStarter: true` prompts

### Building the ZIP

For each selected prompt:

1. **Filename**: slugify title → `cold-outreach-email.prompt.md`
   - Lowercase, spaces → hyphens, strip non-alphanumeric except hyphens
   - Truncate to 60 chars
   - Append `.prompt.md`

2. **Frontmatter**:
   - `description:` from title
   - `input:` list from detected variables (using `VariableDetector.detect(body)`)
   - `model:` from first model tag (or omit if none)
   - `x-loadstash-path:` from path
   - `x-loadstash-tags:` from searchTags
   - `x-loadstash-pinned:` from pinned
   - `x-loadstash-model-tags:` from modelTags (full list)

3. **Body**: convert `{{name}}` → `${input:name}` throughout

4. **`apm.yml`**:
```yaml
name: loadstash-export
version: 1.0.0
description: Exported prompts from Loadstash
type: prompts
```

5. **ZIP structure**:
```
loadstash-export-2026-06-15.zip
├── apm.yml
└── .apm/
    └── prompts/
        ├── cold-outreach-email.prompt.md
        └── ...
```

6. **Save/share**: use Android share sheet (`share_plus`) to let user send/save the ZIP

---

## 4. New Dependencies

```yaml
# pubspec.yaml additions
archive: ^3.6.1          # ZIP read/write
file_picker: ^8.1.4      # File picker for import
share_plus: ^10.1.2      # Share sheet for export
yaml: ^3.1.2              # YAML frontmatter parsing
```

---

## 5. New Files

```
lib/services/
  import_service.dart          # ZIP reading, parsing, calls PromptRepository.create()
  export_service.dart          # Prompt collecting, ZIP building, share
  prompt_file_parser.dart      # .prompt.md frontmatter + body parsing

lib/features/settings/
  widgets/
    export_scope_sheet.dart    # Three-option scope picker
    folder_assignment_sheet.dart  # FolderPickerSheet variant for path-less imports
```

### Modified files
```
pubspec.yaml                   # Add archive, file_picker, share_plus, yaml
lib/features/settings/settings_screen.dart  # Wire Import + Export buttons
```

---

## 6. Edge Cases

| Case | Handling |
|---|---|
| Duplicate prompt title in import | Append ` (2)` to title, import both |
| Variable name invalid for APM (`[A-Za-z][\w-]{0,63}`) | On export, sanitize: lowercase, replace invalid chars with `_`, truncate |
| Body has `{{var}}` with no matching `input:` entry on export | Still adds it to `input:` list (auto-detected by VariableDetector) |
| ZIP has nested subfolders under `.apm/prompts/` | Flatten — all `.prompt.md` files regardless of subfolder depth |
| `apm.yml` missing but `.prompt.md` files present | Reject import — `apm.yml` is required |
| Export with 0 prompts in chosen scope | Show "No prompts to export" snackbar, no ZIP created |
| Very long body (>10k chars) | No limit — export as-is |
