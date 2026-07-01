#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/env.sh
source "$ROOT_DIR/scripts/env.sh"
load_subtitles_env "$ROOT_DIR"

cd "$ROOT_DIR"
xcrun swift test
xcrun swift build --product SubtitlesApp
xcrun swift run SubtitleHarness parse Fixtures/sample.srt >/tmp/subtitles-harness-srt.txt
xcrun swift run SubtitleHarness parse Fixtures/sample.vtt >/tmp/subtitles-harness-vtt.txt
xcrun swift run SubtitleHarness at Fixtures/sample.srt 3.1 --offset 0.3 >/tmp/subtitles-harness-at.txt

grep -q "format=srt" /tmp/subtitles-harness-srt.txt
grep -q "format=webVTT" /tmp/subtitles-harness-vtt.txt
grep -q "Second cue." /tmp/subtitles-harness-at.txt

APP_PATH="$(scripts/package-app.sh | tail -n 1)"
plutil -lint "$APP_PATH/Contents/Info.plist"
test -x "$APP_PATH/Contents/MacOS/Subtitles"

echo "Subtitles checks passed."
