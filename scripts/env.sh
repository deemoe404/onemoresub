#!/usr/bin/env bash

load_subtitles_env() {
    local root_dir="$1"
    local env_file="$root_dir/.env.local"

    if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck source=/dev/null
        source "$env_file"
        set +a
    fi

    if [[ -z "${DEVELOPER_DIR:-}" ]]; then
        local xcode_beta="$HOME/Applications/Xcode-beta.app/Contents/Developer"
        if [[ -d "$xcode_beta" ]]; then
            export DEVELOPER_DIR="$xcode_beta"
        fi
    fi
}
