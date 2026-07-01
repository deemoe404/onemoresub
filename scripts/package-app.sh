#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/env.sh
source "$ROOT_DIR/scripts/env.sh"
load_subtitles_env "$ROOT_DIR"

APP_NAME="${SUBTITLES_APP_NAME:-Subtitles}"
APP_BUNDLE_NAME="${SUBTITLES_APP_BUNDLE_NAME:-$APP_NAME}"
APP_EXECUTABLE_NAME="${SUBTITLES_APP_EXECUTABLE_NAME:-$APP_NAME}"
APP_DIR="$ROOT_DIR/build/$APP_BUNDLE_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
THIRD_PARTY_LICENSES_DIR="$RESOURCES_DIR/ThirdPartyLicenses"
BUNDLE_IDENTIFIER="${SUBTITLES_BUNDLE_IDENTIFIER:-local.Subtitles}"
BUNDLE_SHORT_VERSION="${SUBTITLES_BUNDLE_SHORT_VERSION:-0.1.0}"
BUNDLE_VERSION="${SUBTITLES_BUNDLE_VERSION:-1}"
MINIMUM_SYSTEM_VERSION="${SUBTITLES_MINIMUM_SYSTEM_VERSION:-26.0}"
DISTRIBUTION_CHANNEL="${SUBTITLES_DISTRIBUTION_CHANNEL:-github}"
CODESIGN_IDENTITY="${SUBTITLES_CODESIGN_IDENTITY:--}"
CODESIGN_ENTITLEMENTS="${SUBTITLES_CODESIGN_ENTITLEMENTS:-}"
STATUS_ITEM_TITLE="${SUBTITLES_STATUS_ITEM_TITLE:-Sub}"
SPARKLE_FEED_URL="${SUBTITLES_SPARKLE_FEED_URL:-}"
SPARKLE_PUBLIC_ED_KEY="${SUBTITLES_SPARKLE_PUBLIC_ED_KEY:-}"
SPARKLE_FRAMEWORK_SOURCE="$ROOT_DIR/Vendor/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
SPARKLE_LICENSE_SOURCE="$ROOT_DIR/Vendor/Sparkle/LICENSE"

if [[ -n "${SUBTITLES_SWIFT_PRODUCT:-}" ]]; then
    echo "SUBTITLES_SWIFT_PRODUCT is no longer supported; use SUBTITLES_DISTRIBUTION_CHANNEL=github or appstore" >&2
    exit 1
fi

case "$DISTRIBUTION_CHANNEL" in
    github)
        SWIFT_PRODUCT="SubtitlesApp"
        INCLUDE_SPARKLE=1
        ;;
    appstore)
        SWIFT_PRODUCT="SubtitlesAppStore"
        INCLUDE_SPARKLE=0
        if [[ -z "$CODESIGN_ENTITLEMENTS" ]]; then
            CODESIGN_ENTITLEMENTS="$ROOT_DIR/Subtitles.entitlements"
        fi
        if [[ ! -f "$CODESIGN_ENTITLEMENTS" ]]; then
            echo "App Store channel requires entitlements at: $CODESIGN_ENTITLEMENTS" >&2
            exit 1
        fi
        ;;
    *)
        echo "Unsupported SUBTITLES_DISTRIBUTION_CHANNEL: $DISTRIBUTION_CHANNEL" >&2
        echo "Expected: github or appstore" >&2
        exit 1
        ;;
esac

if [[ "$INCLUDE_SPARKLE" == "1" && -n "$SPARKLE_FEED_URL" && -z "$SPARKLE_PUBLIC_ED_KEY" ]]; then
    echo "SUBTITLES_SPARKLE_PUBLIC_ED_KEY is required when SUBTITLES_SPARKLE_FEED_URL is set" >&2
    exit 1
fi

if [[ "$INCLUDE_SPARKLE" == "1" && -z "$SPARKLE_FEED_URL" && -n "$SPARKLE_PUBLIC_ED_KEY" ]]; then
    echo "SUBTITLES_SPARKLE_FEED_URL is required when SUBTITLES_SPARKLE_PUBLIC_ED_KEY is set" >&2
    exit 1
fi

verify_appstore_entitlements() {
    local entitlements_file
    local sandbox
    local automation
    local user_selected_read_only
    local quicktime_exception
    local quicktime_exception_extra

    entitlements_file="$(mktemp)"
    codesign -d --entitlements - --xml "$APP_DIR" >"$entitlements_file" 2>/dev/null

    sandbox="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$entitlements_file" 2>/dev/null || true)"
    automation="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.automation.apple-events' "$entitlements_file" 2>/dev/null || true)"
    user_selected_read_only="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.files.user-selected.read-only' "$entitlements_file" 2>/dev/null || true)"
    quicktime_exception="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.temporary-exception.apple-events:0' "$entitlements_file" 2>/dev/null || true)"
    quicktime_exception_extra="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.temporary-exception.apple-events:1' "$entitlements_file" 2>/dev/null || true)"

    rm -f "$entitlements_file"

    if [[ "$sandbox" != "true" ]]; then
        echo "App Store channel requires com.apple.security.app-sandbox entitlement" >&2
        exit 1
    fi
    if [[ "$automation" != "true" ]]; then
        echo "App Store channel requires com.apple.security.automation.apple-events entitlement" >&2
        exit 1
    fi
    if [[ "$user_selected_read_only" != "true" ]]; then
        echo "App Store channel requires com.apple.security.files.user-selected.read-only entitlement" >&2
        exit 1
    fi
    if [[ "$quicktime_exception" != "com.apple.QuickTimePlayerX" ]]; then
        echo "App Store channel requires QuickTime Player Apple Events temporary exception" >&2
        exit 1
    fi
    if [[ -n "$quicktime_exception_extra" ]]; then
        echo "App Store channel must not include extra Apple Events temporary exceptions" >&2
        exit 1
    fi
}

cd "$ROOT_DIR"
if [[ "$INCLUDE_SPARKLE" == "1" ]]; then
    "$ROOT_DIR/scripts/prepare-sparkle.sh" >/dev/null
fi
SUBTITLES_DISTRIBUTION_CHANNEL="$DISTRIBUTION_CHANNEL" xcrun swift build -c release --product "$SWIFT_PRODUCT"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/.build/release/$SWIFT_PRODUCT" "$MACOS_DIR/$APP_EXECUTABLE_NAME"
cp "$ROOT_DIR/LICENSE" "$RESOURCES_DIR/LICENSE"

if [[ "$INCLUDE_SPARKLE" == "1" ]]; then
    mkdir -p "$FRAMEWORKS_DIR" "$THIRD_PARTY_LICENSES_DIR"
    /usr/bin/ditto "$SPARKLE_FRAMEWORK_SOURCE" "$FRAMEWORKS_DIR/Sparkle.framework"
    cp "$SPARKLE_LICENSE_SOURCE" "$THIRD_PARTY_LICENSES_DIR/Sparkle-LICENSE"
fi

cat >"$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST

plutil -replace CFBundleDevelopmentRegion -string en "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleExecutable -string "$APP_EXECUTABLE_NAME" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_IDENTIFIER" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleInfoDictionaryVersion -string "6.0" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundlePackageType -string APPL "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleShortVersionString -string "$BUNDLE_SHORT_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleVersion -string "$BUNDLE_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace LSMinimumSystemVersion -string "$MINIMUM_SYSTEM_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace LSUIElement -bool YES "$CONTENTS_DIR/Info.plist"
plutil -replace NSAppleEventsUsageDescription -string "Subtitles reads the current playback position from QuickTime Player when you use Sync." "$CONTENTS_DIR/Info.plist"
plutil -replace NSHighResolutionCapable -bool YES "$CONTENTS_DIR/Info.plist"
plutil -replace SUBDistributionChannel -string "$DISTRIBUTION_CHANNEL" "$CONTENTS_DIR/Info.plist"
plutil -replace SUBStatusItemTitle -string "$STATUS_ITEM_TITLE" "$CONTENTS_DIR/Info.plist"

if [[ "$INCLUDE_SPARKLE" == "1" && -n "$SPARKLE_FEED_URL" ]]; then
    plutil -replace SUFeedURL -string "$SPARKLE_FEED_URL" "$CONTENTS_DIR/Info.plist"
    plutil -replace SUPublicEDKey -string "$SPARKLE_PUBLIC_ED_KEY" "$CONTENTS_DIR/Info.plist"
fi

codesign_nested_args=(--force --sign "$CODESIGN_IDENTITY")
codesign_app_args=(--force --sign "$CODESIGN_IDENTITY" --identifier "$BUNDLE_IDENTIFIER")
if [[ "${SUBTITLES_CODESIGN_HARDENED_RUNTIME:-0}" == "1" ]]; then
    codesign_nested_args+=(--options runtime)
    codesign_app_args+=(--options runtime)
fi
if [[ -n "$CODESIGN_ENTITLEMENTS" ]]; then
    codesign_app_args+=(--entitlements "$CODESIGN_ENTITLEMENTS")
fi

if [[ "$INCLUDE_SPARKLE" == "1" ]]; then
    for nested_code in \
        "$FRAMEWORKS_DIR/Sparkle.framework/XPCServices/"*.xpc \
        "$FRAMEWORKS_DIR/Sparkle.framework/Updater.app" \
        "$FRAMEWORKS_DIR/Sparkle.framework/Autoupdate"; do
        codesign "${codesign_nested_args[@]}" "$nested_code"
    done
    codesign "${codesign_nested_args[@]}" "$FRAMEWORKS_DIR/Sparkle.framework"
fi
codesign "${codesign_app_args[@]}" "$APP_DIR"

if [[ "$DISTRIBUTION_CHANNEL" == "appstore" ]]; then
    verify_appstore_entitlements
fi

echo "$APP_DIR"
