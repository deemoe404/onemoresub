#!/usr/bin/env bash
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-$HOME/Applications/Xcode-beta.app/Contents/Developer}"

xcrun swift test
xcrun swift build --product SubtitlesApp
xcrun swift run SubtitleHarness parse Fixtures/sample.srt >/tmp/subtitles-harness-srt.txt
xcrun swift run SubtitleHarness parse Fixtures/sample.vtt >/tmp/subtitles-harness-vtt.txt
xcrun swift run SubtitleHarness at Fixtures/sample.srt 3.1 --offset 0.3 >/tmp/subtitles-harness-at.txt

grep -q "format=srt" /tmp/subtitles-harness-srt.txt
grep -q "format=webVTT" /tmp/subtitles-harness-vtt.txt
grep -q "Second cue." /tmp/subtitles-harness-at.txt

echo "Subtitles checks passed."
