# Xcode - Mouse Wheel Zoom

VS Code–style ⌘ + mouse wheel zoom for Xcode on macOS, with an on-screen zoom indicator.


![Cmd + scroll zooming Xcode, with the zoom HUD](docs/demo.gif)

A HUD shows how far you have zoomed. Ctrl-Opt-Cmd-Z pauses and resumes the agent.

## Requirements

- macOS 14+
- Accessibility permission (you get asked on first run)

## Run

```
xcodegen generate
open ScrollZoom.xcodeproj   # build and run with Cmd-R
```

## Install for good

```
xcodegen generate
xcodebuild -scheme ScrollZoom -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/ScrollZoom.app /Applications/
open /Applications/ScrollZoom.app
```

Turn on **Start at Login** and it comes back after every reboot.

![Menu bar](docs/menu.png)

## Settings

Open **Settings...** from the menu bar.

![Settings window](docs/settings.png)

- **Enabled** - enable/disable the app
- **Start at Login** - registers the app as a login item.
- **Sensitivity** - adjust trackpad scrolling (mouse wheels always zoom one step)

## Targets

Works with any app that uses ⌘= / ⌘- for zoom, not just Xcode. Add apps from Settings → Add Application…, or via:
```
defaults write com.erykszczesniak.ScrollZoom SZTargets -array-add \
  '{ bundleIdentifier = "com.example.editor"; }'
```

![Adding an app to Targets](docs/targets.gif)


## How it works

ScrollZoom is a lightweight menu bar app that listens for ⌘ + scroll, converts it to ⌘= / ⌘-, and sends the shortcut only to the frontmost supported app using CGEventPostToPid.

No code injection, SIP changes, plugins, or third-party dependencies.

```
Cmd + mouse wheel
   |
   v
SZEventTap -> SZGestureInterpreter -> SZTargetMatcher -> SZActionMapper -> SZKeystrokeSynthesizer -> Xcode
 (observe)     (delta to intent)      (act or pass)      (intent to keys)   (CGEventPostToPid)
```

- **Core**, pure logic and fully unit tested: `SZGestureInterpreter` (throttling, trackpad accumulation, momentum ignored), `SZTargetMatcher` and `SZTargetRule` (per-app rules), `SZActionMapper` (intent to shortcut), `SZZoomLevelTracker` (the step count behind the HUD), `SZPreferences`.
- **Edge**, thin wrappers behind protocols: `SZEventTap`, `SZAccessibility`, `SZKeystrokeSynthesizer`, `SZHotKey`, `SZLoginItem`, `NSEvent+SZModifiers`.
- **UI and app**: `SZMenuController` (four states: permission needed, paused, active, armed), `SZZoomHUD` (click-through overlay), a SwiftUI Settings window bridged into the Objective-C app, `SZZoomController` (wires the pipeline, every dependency injected), `SZPermissionGate` (first-run explainer, recovers if permission is revoked).
- **Strings** all live in `SZStrings.h` and `Localizable.strings`.
