# Overcast

Blinds closed, three monitors on, and some days you genuinely don't know if
it's sunny or the apocalypse outside — because you haven't looked up in six
hours. Overcast is the compromise between "toxic productivity" and "touching
grass." A glance at the tray, no need to actually go outside.

A tiny, free, open-source floating macOS widget for devs who see daylight
mostly as a rumor. Shows the current time, real-time weather as a
plain-English descriptor ("Mild Sun", "Overcast", "Rainy"), and a
configurable mood/personality that reacts to events like a failed build or a
found bug.

## Stack

- Swift + SwiftUI + AppKit (`NSPanel` floating window) — no Electron, minimal footprint
- [Open-Meteo](https://open-meteo.com) — free, no API key, current weather via WMO codes
- Swift Package Manager — buildable from the CLI or opened directly in Xcode

## Requirements

- macOS 13+
- Xcode 15+ **or** just the Command Line Tools (`xcode-select --install`)

## Build & Run

```bash
swift build
swift run
```

Or open `Package.swift` directly in Xcode (File → Open).

## Building a distributable .app

```bash
chmod +x build-app.sh
./build-app.sh
open Overcast.app
```

## Configuration

Create `~/.config/overcast/config.json` (copy from `config.example.json`):

```json
{
  "fallbackLatitude": 11.2588,
  "fallbackLongitude": 75.7804,
  "refreshIntervalMinutes": 15
}
```

Used when location permission isn't granted.

## Triggering mood events

Any script — a git hook, CI job, or terminal command — can change the
companion's mood by writing to a trigger file:

```bash
echo '{"event":"bugFound"}'    > ~/.config/overcast/event.json
echo '{"event":"buildPassed"}' > ~/.config/overcast/event.json
echo '{"event":"cheerUp"}'     > ~/.config/overcast/event.json
echo '{"event":"focusMode"}'   > ~/.config/overcast/event.json
echo '{"event":"reset"}'       > ~/.config/overcast/event.json
```

Example git hook (`.git/hooks/pre-commit`) that reacts to a failing test suite:

```bash
#!/bin/bash
if ! swift test; then
  echo '{"event":"bugFound"}' > ~/.config/overcast/event.json
  exit 1
fi
```

## Installing via Homebrew (once released)

```bash
brew tap yourname/overcast
brew install --cask overcast
```

Builds are unsigned and un-notarized (keeps this project fully free to
develop and distribute). The Cask runs `xattr -cr` on first install to clear
the quarantine flag so Gatekeeper doesn't block launch. Alternatively,
right-click the app → Open the first time.

## License

MIT — see `LICENSE`.
