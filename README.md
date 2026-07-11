# ScrollZoom

⌘ + scroll wheel zoom for Xcode (macOS).

![⌘ + scroll zooming Xcode](docs/demo.gif)

## Requirements

- macOS 14 or later
- Accessibility permission (prompted on first run; if the toggle is on but nothing happens after a rebuild, remove ScrollZoom from the Accessibility list and re-add it)

## Run

```
xcodegen generate
open ScrollZoom.xcodeproj   # build & run (⌘R)
```

Grant Accessibility when prompted, then hold ⌘ and scroll in Xcode. ⌃⌥⌘Z pauses/resumes.

## Install

```
xcodegen generate
xcodebuild -scheme ScrollZoom -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/ScrollZoom.app /Applications/
open /Applications/ScrollZoom.app
```

Then tick **Start at Login** in the menu — done, it survives reboots:

![Start at Login](docs/menu.png)

## How it works & limits

- External Accessibility agent: a global scroll monitor detects ⌘ + scroll and sends the frontmost target app its own font-size shortcuts (⌘= / ⌘-) via `CGEvent`.
- Stepped font-size zoom, not renderer-level smooth zoom — Xcode has no plugin API, so the renderer can't be owned.
- No SIP changes, no code injection; may need re-tuning across Xcode versions. macOS-only.
