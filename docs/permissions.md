# Permissions

This document explains the permissions One More Cap uses for playback sync.

## QuickTime Automation

One More Cap reads QuickTime Player's current movie time through QuickTime's
scripting interface for Sync calibration. macOS may require Automation
permission for that behavior.

If the hover Sync control cannot read QuickTime Player, use
`Permission > Automation...`, then allow One More Cap to read QuickTime Player
in System Settings. The menu and hover controls remain usable without that
permission.

The app only uses this permission to read the current playback position for
sync. If QuickTime Player is not running, has no open movie document, is missing
permission, or returns no position data, Sync reports the calibration failure
and leaves the current subtitle timing unchanged.

## Apple TV Accessibility

GitHub/full builds also include an Apple TV sync target. That path reads TV.app
state through Accessibility and is intentionally excluded from the App Store
channel.

App Store builds sync with QuickTime Player only. GitHub/full builds can sync
with QuickTime Player or Apple TV.

## Channel Boundary

The App Store channel intentionally excludes:

- Sparkle
- ApplicationServices
- Apple TV Accessibility support

That boundary is controlled through `ONEMORECAP_DISTRIBUTION_CHANNEL` and the
channel-sensitive SwiftPM manifest.
