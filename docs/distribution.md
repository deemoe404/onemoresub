# Distribution

This document covers packaging, signing, update delivery, and release
automation. The user-facing app overview lives in the top-level
[README](../README.md).

## Distribution Channels

The package has two app products:

| Channel | Product | Includes |
| --- | --- | --- |
| GitHub/full | `OneMoreCapApp` | QuickTime sync, Apple TV sync through Accessibility, Sparkle updates |
| App Store | `OneMoreCapAppStore` | QuickTime read-only sync only; no Sparkle or Apple TV Accessibility target |

`scripts/package-app.sh` maps channels to fixed products: `github` selects
`OneMoreCapApp`, and `appstore` selects `OneMoreCapAppStore`. The product is not
overridable by environment because that would weaken the App Store channel
boundary.

Package each channel with:

```sh
mise exec -- scripts/package-app.sh
ONEMORECAP_DISTRIBUTION_CHANNEL=appstore mise exec -- scripts/package-app.sh
```

## Signing

`scripts/package-app.sh` defaults to ad-hoc signing, so a public checkout can
build a local `.app` bundle without a private Apple signing identity.

For personal signed builds, put local-only overrides in `.env.local`. That file
is ignored by git; `.env.local.example` documents the supported variables:

```sh
ONEMORECAP_CODESIGN_IDENTITY="Apple Development: Your Name (TEAMID)"
ONEMORECAP_BUNDLE_IDENTIFIER="com.example.one-more-cap"
```

The same values can also be supplied as environment variables for one-off
builds.

The App Store channel automatically uses `OneMoreCap.entitlements` when no custom
`ONEMORECAP_CODESIGN_ENTITLEMENTS` value is set. That entitlement file enables
App Sandbox, user-selected subtitle file read access, and Apple Events access to
QuickTime Player.

Current public release artifacts are ad-hoc signed. Developer ID signing,
notarization, and App Store upload signing are separate distribution steps.
Packaged app bundles include a copy of the license in `Contents/Resources`.

## Sparkle Updates

The GitHub/full channel uses [Sparkle](https://sparkle-project.org/) for manual
and automatic update checks. Sparkle is downloaded into the ignored
`Vendor/Sparkle/` directory by `scripts/prepare-sparkle.sh`; the binary
framework is not committed to git. The App Store channel does not link Sparkle
and does not show the update menu item.

Development builds without `ONEMORECAP_SPARKLE_FEED_URL` and
`ONEMORECAP_SPARKLE_PUBLIC_ED_KEY` still build and run, but the `Check for
Updates...` menu item reports that updates are not configured for that build.

Generate or inspect the Sparkle EdDSA key with:

```sh
mise exec -- scripts/generate-sparkle-keys.sh
mise exec -- scripts/generate-sparkle-keys.sh -p
mise exec -- scripts/generate-sparkle-keys.sh -x /tmp/onemorecap-sparkle-private-key
```

For GitHub Release appcasts, set these repository secrets:

```sh
ONEMORECAP_SPARKLE_PUBLIC_ED_KEY
ONEMORECAP_SPARKLE_PRIVATE_KEY
```

`ONEMORECAP_SPARKLE_PUBLIC_ED_KEY` is the public key printed by
`generate-sparkle-keys.sh -p`. `ONEMORECAP_SPARKLE_PRIVATE_KEY` is the exact
contents of the private key file exported with `-x`; do not commit that file.

Release builds require both secrets. The release workflow embeds the public key
and a stable feed URL in the app, generates `appcast.xml`, and uploads it as a
release asset. The app feed URL is:

```text
https://github.com/deemoe404/onemorecap/releases/latest/download/appcast.xml
```

If the app is renamed later, keep `ONEMORECAP_BUNDLE_IDENTIFIER`, the Sparkle
public/private key pair, and the feed URL stable. `ONEMORECAP_APP_NAME`,
`ONEMORECAP_APP_BUNDLE_NAME`, `ONEMORECAP_APP_EXECUTABLE_NAME`, and
`ONEMORECAP_STATUS_ITEM_TITLE` can change for display and packaging purposes.

## Release Automation

GitHub Actions runs `scripts/check.sh` on pushes and pull requests to `main`.
That check builds both `OneMoreCapApp` and `OneMoreCapAppStore`, then verifies
that the GitHub/full package includes Sparkle and the App Store package does
not.

When a GitHub Release is published, the release workflow builds the tagged
checkout on a macOS runner, packages `build/One More Cap.app`, zips the app
bundle, generates the Sparkle appcast, and uploads both files back to the
Release assets. It also produces an App Store-channel workflow artifact without
Sparkle.

Release tags must use `vX.Y.Z` or `X.Y.Z` format. That tag is written into the
app bundle short version, and the GitHub Actions run number is written into the
bundle build number. Release asset uploads fail if an asset with the same name
already exists.
