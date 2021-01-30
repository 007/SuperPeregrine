#!/bin/bash
# Standard presets for H.265 encoding from high-bitrate source
time ffmpeg -hide_banner -i "$1" -c:v libx265 -crf 22 -level 4.1 -aq-mode 3 -aq-strength 0.8 -psy-rd 0.8:0:0 -deblock -3:-3 -vf "$(
ffmpeg -ss 314 -i "$1" -c:v libx264 -preset ultrafast -t 314 -vf cropdetect -map 0:0 -f null - 2>&1 | awk '/Parsed_cropdetect/{print $14}' | tail -1
)" -c:a eac3 -c:s srt -b:a 640k -map_metadata -1 -metadata:s:a:0 language=eng -metadata:s:v:0 language=eng -metadata:s:s:0 language=eng -preset slow "${1%.mkv}.265.mkv"
