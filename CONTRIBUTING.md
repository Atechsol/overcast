# Contributing to Overcast

Thanks for wanting to poke at this. It's a small, single-purpose widget —
keep changes focused and it'll be easy to review.

## Setup

```bash
git clone https://github.com/<owner>/overcast.git
cd overcast
swift build
swift run
```

Or open `Package.swift` in Xcode (File → Open).

## Making changes

1. Fork, branch off `main`.
2. Build and manually run the widget after your change — see the "Build a
   distributable .app" section in the README. There's no UI test harness, so
   actually look at the floating panel before opening a PR.
3. If you're touching more than one running copy at once (Xcode debug build
   + `build-app.sh` release build both running), quit the old one first —
   `pkill -f Overcast` — or you'll be debugging two live instances by accident.
4. Keep PRs scoped to one thing. A styling tweak and a new mood-event type
   should be two PRs, not one.

## What CI checks

Every PR runs `.github/workflows/ci.yml`:
- `swift build` (debug)
- `swift build -c release`
- `swift test` (currently a no-op — there's no test target yet; adding real
  unit tests for pure-logic pieces like `WeatherDescriptor.from(code:isDay:)`
  or `MoodManager` is a great first contribution)

Merges to `main` require this to pass.

## Releases

Maintainer-only: pushing a tag matching `v*` (e.g. `v0.2.0`) triggers
`.github/workflows/release.yml`, which builds `Overcast.app`, zips it,
computes its sha256, and publishes a GitHub Release with the zip attached.
The sha256 then needs to be copied into the `homebrew-overcast` tap's
`Casks/overcast.rb`.

## Code style

- No comments explaining *what* code does — names should cover that. Comments
  only for non-obvious *why* (see existing files for the tone).
- Don't add abstractions/config options for hypothetical future needs — this
  is a small app, keep it small.
