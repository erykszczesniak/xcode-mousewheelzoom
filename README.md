# Xcode - Mouse Wheel Zoom

⌘ + mouse-wheel zoom for Xcode (macOS).

![⌘ + scroll zooming Xcode](docs/demo.gif)

## Requirements

- macOS 14+
- Accessibility permission (prompted on first run; if the toggle is on but nothing happens after a rebuild, remove ScrollZoom from the Accessibility list and re-add it)

## Run

```
xcodegen generate
open ScrollZoom.xcodeproj   # build & run (⌘R)
```

Grant Accessibility when prompted, then hold ⌘ and scroll in Xcode. ⌃⌥⌘Z pauses/resumes.

## Install Permanently

```
xcodegen generate
xcodebuild -scheme ScrollZoom -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/ScrollZoom.app /Applications/
open /Applications/ScrollZoom.app
```

Enable **Start at Login** from the menu.

![Start at Login](docs/menu.png)


## How it works 

ScrollZoom is a menu-bar app that adds VS Code–style ⌘ + mouse wheel zoom to Xcode.

It listens for ⌘ + scroll via the Accessibility API, translates the gesture into `⌘=` / `⌘-`, and sends the shortcuts directly to the frontmost Xcode process with `CGEventPostToPid`. No SIP changes, no code injection, no third-party dependencies — pure Cocoa.


```
⌘ + mouse wheel
   │
   ▼
SZEventTap ──► SZGestureInterpreter ──► SZTargetMatcher ──► SZActionMapper ──► SZKeystrokeSynthesizer ──► Xcode (⌘= / ⌘-)
 (observe)      (delta → intent)         (act or pass)       (intent → keys)     (CGEventPostToPid)
```

- **Core** (pure logic, 100% unit-testable): `SZGestureInterpreter` (delta → intent: throttling, trackpad accumulation, momentum ignored), `SZTargetMatcher` + `SZTargetRule` (per-app rules), `SZActionMapper` (intent → shortcut), `SZPreferences` (`NSUserDefaults` config; add target apps with a single `defaults write`).
- **Edge** (thin wrappers behind protocols): `SZEventTap`, `SZAccessibility`, `SZKeystrokeSynthesizer`, `SZHotKey` (⌃⌥⌘Z pause), `SZLoginItem` (`SMAppService`), `NSEvent+SZModifiers`.
- **UI / App**: `SZMenuController` (four states: permission needed / Paused / Active / Armed), `SZZoomController` (ties the pipeline together, every dependency injected behind a protocol), `SZPermissionGate` (permission gate with first-run explainer and auto-recovery after revocation).
- **Strings**: all user-facing copy in `SZStrings.h` (`NSLocalizedString`) + `Localizable.strings`.
