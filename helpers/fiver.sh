#!/bin/bash
# Standard presets for H.265 encoding from high-bitrate source
time ffmpeg -hide_banner -i "$1" -c:v libx265 -crf 20 -level 4.1 -preset slow -x265-params high-tier=1:repeat-headers=1:aud=1:hrd=1:level-idc=4.1:aq-mode=3:aq-strength=0.8 -vf "$(
ffmpeg -ss 314 -i "$1" -c:v libx264 -preset ultrafast -t 314 -vf cropdetect -map 0:0 -f null - 2>&1 | awk '/Parsed_cropdetect/{print $14}' | tail -1
)" -c:a eac3 -b:a 640k -c:s copy -map_metadata -1 -metadata:s:v:0 language=eng -metadata:s:a:0 language=eng -metadata:s:s:0 language=eng "${2}"
