# How it works

ScrollZoom is a lightweight menu bar app that listens for ⌘ + scroll, converts it to ⌘= / ⌘-, and sends the shortcut only to the frontmost supported app using CGEventPostToPid.

No code injection, SIP changes, plugins, or third-party dependencies.

What it is not: a smooth, renderer-level zoom. Xcode has no plugin API, so nothing outside it can own the text rendering. This is a stepped font-size zoom on a natural gesture.

```
Cmd + mouse wheel
   |
   v
SZEventTap -> SZGestureInterpreter -> SZTargetMatcher -> SZActionMapper -> SZKeystrokeSynthesizer -> Xcode
 (observe)     (delta to intent)      (act or pass)      (intent to keys)   (CGEventPostToPid)
```

## Layers

- **Core**, pure logic and fully unit tested: `SZGestureInterpreter` (throttling, trackpad accumulation, momentum ignored), `SZTargetMatcher` and `SZTargetRule` (per-app rules), `SZActionMapper` (intent to shortcut), `SZZoomLevelTracker` (the step count behind the HUD), `SZPreferences`.
- **Edge**, thin wrappers behind protocols: `SZEventTap`, `SZAccessibility`, `SZKeystrokeSynthesizer`, `SZHotKey`, `SZLoginItem`, `NSEvent+SZModifiers`.
- **UI and app**: `SZMenuController` (four states: permission needed, paused, active, armed), `SZZoomHUD` (click-through overlay), a SwiftUI Settings window bridged into the Objective-C app, `SZZoomController` (wires the pipeline, every dependency injected), `SZPermissionGate` (first-run explainer, recovers if permission is revoked).
- **Strings** all live in `SZStrings.h` and `Localizable.strings`.

## Why keystrokes and not something better

Xcode dropped plugin support in Xcode 8, and Source Editor Extensions get no access to mouse events or font size. An external agent that observes the gesture and synthesizes the app's own shortcuts is the only route left that does not weaken the system. Code injection (re-signing Xcode, disabling SIP) would work, but it is not worth what it costs.
