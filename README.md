# Xcode - Mouse Wheel Zoom

⌘ + mouse-wheel zoom for Xcode (macOS) — the VS Code gesture, with an on-screen zoom level.

![⌘ + scroll zooming Xcode, with the zoom HUD](docs/demo.gif)

## Requirements

- macOS 14+
- Accessibility permission (prompted on first run; if the toggle is on but nothing happens after a rebuild, remove ScrollZoom from the Accessibility list and re-add it)

## Run

```
xcodegen generate
open ScrollZoom.xcodeproj   # build & run (⌘R)
```

Grant Accessibility when prompted, then hold ⌘ and scroll in Xcode. A HUD shows how many steps you have zoomed. ⌃⌥⌘Z pauses and resumes the agent.

## Install Permanently

```
xcodegen generate
xcodebuild -scheme ScrollZoom -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/ScrollZoom.app /Applications/
open /Applications/ScrollZoom.app
```

Enable **Start at Login** from the menu or in Settings, and the agent comes back after every reboot.

![Menu bar](docs/menu.png)

## Settings

Open **Settings…** from the menu bar (⌘, once the window is up, ⌘W to close).

![Settings window](docs/settings.png)

- **Enabled** — master switch, mirrored by the ⌃⌥⌘Z hotkey.
- **Start at Login** — registers the agent as a login item (`SMAppService`).
- **Sensitivity** — how far a trackpad swipe travels per zoom step (25 px at Low, 8 px at High). A mouse wheel always steps once per notch, so this only affects trackpads. Changes apply live.

## Targets: not just Xcode

Xcode is the default target, but any app with ⌘= / ⌘- font-size shortcuts works — editors, browsers, terminals. Click **Add Application…**, pick the app, and its bundle identifier becomes a new target rule. Chrome, for example, then zooms with the same gesture.

![Adding an app to Targets](docs/targets.gif)

Each target has its own switch (turn it off without removing it) and a trash button (with confirmation). Everything is stored in `NSUserDefaults`, so a target can also be added without the UI:

```
defaults write com.erykszczesniak.ScrollZoom SZTargets -array-add \
  '{ bundleIdentifier = "com.example.editor"; }'
```

Optional per-target keys `zoomInKeyCode` / `zoomOutKeyCode` (virtual key codes, posted with ⌘) override the default ⌘= / ⌘- mapping for apps that bind zoom elsewhere.

## How it works

ScrollZoom is a menu-bar agent that adds VS Code–style ⌘ + mouse wheel zoom to Xcode.

It listens for ⌘ + scroll via the Accessibility API, translates the gesture into `⌘=` / `⌘-`, and sends the shortcuts to the frontmost target process with `CGEventPostToPid` — never system-wide, so a zoom step can only reach the app you were actually pointing at. No SIP changes, no code injection, no third-party dependencies — pure Cocoa.

Note what this is not: a renderer-level, pixel-smooth zoom. Xcode has no plugin API, so nobody outside it can own the text rendering. This is a stepped font-size zoom mapped onto a natural gesture — which, in day-to-day use, is what you actually wanted.

```
⌘ + mouse wheel
   │
   ▼
SZEventTap ──► SZGestureInterpreter ──► SZTargetMatcher ──► SZActionMapper ──► SZKeystrokeSynthesizer ──► Xcode (⌘= / ⌘-)
 (observe)      (delta → intent)         (act or pass)       (intent → keys)     (CGEventPostToPid)
```

- **Core** (pure logic, 100% unit-testable): `SZGestureInterpreter` (delta → intent: throttling, trackpad accumulation, momentum ignored), `SZTargetMatcher` + `SZTargetRule` (per-app rules), `SZActionMapper` (intent → shortcut), `SZZoomLevelTracker` (per-app step count behind the HUD), `SZPreferences` (`NSUserDefaults` config).
- **Edge** (thin wrappers behind protocols): `SZEventTap`, `SZAccessibility`, `SZKeystrokeSynthesizer`, `SZHotKey` (⌃⌥⌘Z pause), `SZLoginItem` (`SMAppService`), `NSEvent+SZModifiers`.
- **UI / App**: `SZMenuController` (four states: permission needed / Paused / Active / Armed), `SZZoomHUD` (the non-activating, click-through overlay), the SwiftUI Settings window bridged into the Objective-C app, `SZZoomController` (ties the pipeline together, every dependency injected behind a protocol), `SZPermissionGate` (first-run explainer, auto-recovery after revocation).
- **Strings**: all user-facing copy in `SZStrings.h` (`NSLocalizedString`) + `Localizable.strings`.
