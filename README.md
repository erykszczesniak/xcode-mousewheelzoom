# ScrollZoom

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

## How it works & limits

- Uses the Accessibility API (`CGEvent`) to send Xcode's zoom shortcuts.
- No code injection or SIP changes.
