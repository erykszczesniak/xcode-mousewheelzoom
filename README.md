# Xcode - Mouse Wheel Zoom

Hold Cmd, scroll, and Xcode's font grows or shrinks. The VS Code gesture, on macOS.

![Cmd + scroll zooming Xcode, with the zoom HUD](docs/demo.gif)

A HUD shows how far you have zoomed. Ctrl-Opt-Cmd-Z pauses and resumes the agent.

## Requirements

- macOS 14 or newer
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

- **Enabled** turns the agent off and on. Same as the Ctrl-Opt-Cmd-Z hotkey.
- **Start at Login** registers the app as a login item.
- **Sensitivity** sets how far a trackpad swipe travels per zoom step, from 25 px (Low) to 8 px (High). A mouse wheel always steps once per notch, so this only matters on a trackpad. Changes apply right away.

## Targets

Xcode is the default, but any app with Cmd-+ / Cmd-- font shortcuts works. Editors, browsers, terminals. Click **Add Application...**, pick the app, done. Chrome zooms with the same gesture from then on.

![Adding an app to Targets](docs/targets.gif)

Each target has its own switch, so you can turn one off without removing it. You can also add one without the UI:

```
defaults write com.erykszczesniak.ScrollZoom SZTargets -array-add \
  '{ bundleIdentifier = "com.example.editor"; }'
```

If an app binds zoom to other keys, set `zoomInKeyCode` and `zoomOutKeyCode` on its entry.

## How it works

ScrollZoom watches for Cmd + scroll through the Accessibility API, turns the gesture into Cmd-+ or Cmd--, and sends those keys straight to the app in front with `CGEventPostToPid`. Never system wide, so a zoom step can only reach the app you were pointing at. No SIP changes, no code injection, no third-party dependencies. Pure Cocoa.

What it is not: a smooth, renderer-level zoom. Xcode has no plugin API, so nobody outside it can own the text rendering. This is a stepped font-size zoom on a natural gesture, which in daily use is what you wanted anyway.

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
