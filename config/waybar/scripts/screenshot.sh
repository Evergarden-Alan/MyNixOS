#!/usr/bin/env bash

COORDS=$(slurp)
if [ -z "$COORDS" ]; then
    exit 0
fi
SOUND=$(for p in /run/current-system/sw/share/sounds/freedesktop/stereo/camera-shutter.oga /nix/store/*/share/sounds/freedesktop/stereo/camera-shutter.oga /usr/share/sounds/freedesktop/stereo/camera-shutter.oga; do [[ -f "$p" ]] && { echo "$p"; break; }; done)
[ -n "$SOUND" ] && pw-play "$SOUND" > /dev/null 2>&1 &
grim -g "$COORDS" - | wl-copy && notify-send "Screenshot" "copy to clipboard"
