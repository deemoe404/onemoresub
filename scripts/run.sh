#!/usr/bin/env bash
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-$HOME/Applications/Xcode-beta.app/Contents/Developer}"

exec xcrun swift run SubtitlesApp
