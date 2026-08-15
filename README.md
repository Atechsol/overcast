# Climeout

A tiny, free, open-source floating macOS widget for developers who lose track of
time and daylight while heads-down in code. Shows the current time, real-time
weather as a plain-English descriptor ("Mild Sun", "Overcast", "Rainy"), and a
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
open Climeout.app
```

## Configuration

Create `~/.config/climeout/config.json` (copy from `config.example.json`):

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
echo '{"event":"bugFound"}'    > ~/.config/climeout/event.json
echo '{"event":"buildPassed"}' > ~/.config/climeout/event.json
echo '{"event":"cheerUp"}'     > ~/.config/climeout/event.json
echo '{"event":"focusMode"}'   > ~/.config/climeout/event.json
echo '{"event":"reset"}'       > ~/.config/climeout/event.json
```

Example git hook (`.git/hooks/pre-commit`) that reacts to a failing test suite:

```bash
#!/bin/bash
if ! swift test; then
  echo '{"event":"bugFound"}' > ~/.config/climeout/event.json
  exit 1
fi
```

## Installing via Homebrew (once released)

```bash
brew tap yourname/climeout
brew install --cask climeout
```

Builds are unsigned and un-notarized (keeps this project fully free to
develop and distribute). The Cask runs `xattr -cr` on first install to clear
the quarantine flag so Gatekeeper doesn't block launch. Alternatively,
right-click the app → Open the first time.

## License

MIT — see `LICENSE`.
