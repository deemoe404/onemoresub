# Development

This document covers local development and source builds. The user-facing app
overview lives in the top-level [README](../README.md).

## Requirements

- macOS with Xcode or Xcode beta
- SwiftPM through Xcode
- Project-local tooling; do not require global dependency installation for this
  repo

The scripts use the active `xcode-select` toolchain by default. If
`$HOME/Applications/Xcode-beta.app/Contents/Developer` exists, the scripts use
it automatically. Set `DEVELOPER_DIR` to override that behavior.

## Common Commands

```sh
mise exec -- scripts/check.sh
mise exec -- scripts/run.sh
mise exec -- scripts/package-app.sh
ONEMORECAP_DISTRIBUTION_CHANNEL=appstore mise exec -- scripts/package-app.sh
```

The default packaged app is the GitHub/full channel and is written to
`build/One More Cap.app`. Set `ONEMORECAP_DISTRIBUTION_CHANNEL=appstore` to
package the App Store channel.

`scripts/check.sh` prepares Sparkle for the GitHub/full channel, then builds and
packages both channels. GitHub/full packaging also prepares Sparkle. The App
Store channel uses a Sparkle-free SwiftPM manifest and does not require
`Vendor/Sparkle`.

If you run raw `swift build --product OneMoreCapApp` or `swift run` commands in
a fresh checkout, run this first:

```sh
mise exec -- scripts/prepare-sparkle.sh
```

## CLI Harness

```sh
mise exec -- swift run SubtitleHarness parse Fixtures/sample.srt
mise exec -- swift run SubtitleHarness at Fixtures/sample.srt 3.1 --offset 0.3
```

The harness is useful for parser, timeline, and offset checks without launching
the macOS app.

## App Behavior During Development

- The menu bar item uses the One More Cap template icon.
- The floating subtitle window stays above normal windows and attempts to join
  fullscreen Spaces.
- Drag `.srt`, `.vtt`, or `.webvtt` files onto the subtitle window to replace
  the active subtitle.
- Hover over the subtitle window to reveal the Liquid Glass toolbar and the
  subtitle container chrome.
- Drag the marked left or right edge region of the subtitle container to adjust
  subtitle width. Height is calculated from the current subtitle text and system
  caption style.
- Hide or reopen the subtitle window from the menu bar.
- Use the hover Sync control to read the current player position. After
  calibration, subtitles continue from that player time using the local clock.
- If the selected player is not running, has no open movie document, is missing
  permission, or returns no position data, Sync reports the calibration failure
  and leaves the current subtitle timing unchanged.

## Core Boundary

Keep `SubtitleCore` AppKit-free so parser, timeline, and clock behavior stay
unit-testable.
