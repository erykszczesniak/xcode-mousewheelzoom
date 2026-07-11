# ScrollZoom

⌘ + scroll wheel zoom for Xcode (macOS).

![ScrollZoom menu](docs/menu.png)

## Requirements

- macOS 14 or later
- Accessibility permission (prompted on first run)

## Run

```
xcodegen generate
open ScrollZoom.xcodeproj   # build & run (⌘R)
```

Grant Accessibility when prompted, then hold ⌘ and scroll in Xcode. ⌃⌥⌘Z pauses/resumes.

## How it works & limits

- External Accessibility agent: a global scroll monitor detects ⌘ + scroll and sends the frontmost target app its own font-size shortcuts (⌘= / ⌘-) via `CGEvent`.
- Stepped font-size zoom, not renderer-level smooth zoom — Xcode has no plugin API, so the renderer can't be owned.
- No SIP changes, no code injection; may need re-tuning across Xcode versions. macOS-only.

Add another app:

```
defaults write com.erykszczesniak.ScrollZoom SZTargets -array-add \
  '{ bundleIdentifier = "com.example.editor"; editorRoles = (AXTextArea); }'
```
