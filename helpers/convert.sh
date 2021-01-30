#!/bin/bash
set -eu

#set -x

BLOCK_SIZE=4
TARGET_W=1280
TARGET_H=720

O_JSON="$(ffprobe -v quiet -print_format json -show_format -show_streams "${1}")"

O_VIDEO="$(jq -c '.streams[]|select(.codec_type=="video")|{width:.width,height:.height}' <<< "$O_JSON")"
ORIGINAL_WIDTH="$(jq -r .width <<< "$O_VIDEO")"
ORIGINAL_HEIGHT="$(jq -r .height <<< "$O_VIDEO")"

O_AUDIO="$(jq -c '.streams[]|select(.codec_type=="audio")|{codec:.codec_name,channels:.channels}' <<< "$O_JSON")"
O_ACODEC="$(jq -r .codec <<< "$O_AUDIO")"
O_ACHANNELS="$(jq -r .channels <<< "$O_AUDIO")"

REMAP_OPTIONS=(
-movflags
+faststart
-map_metadata
-1
-metadata:s:a:0
language=eng
)

VCODEC_OPTIONS=()
ACODEC_OPTIONS=()

if [ "$ORIGINAL_WIDTH" -gt "$TARGET_W" ] || [ "$ORIGINAL_HEIGHT" -gt "$TARGET_H" ]; then
  # convert video
  VCODEC_OPTIONS+=("-c:v" "h264")
  VCODEC_OPTIONS+=("-pix_fmt" "yuv420p")
  VCODEC_OPTIONS+=("-vf" "scale='if(gt(iw/${TARGET_W},ih/${TARGET_H}),min(iw,${TARGET_W}),-${BLOCK_SIZE})':'if(gt(iw/${TARGET_W},ih/${TARGET_H}),-${BLOCK_SIZE},min(ih,${TARGET_H}))':flags=lanczos,setsar=sar=1/1")
  VCODEC_OPTIONS+=("-preset" "veryslow")

else
  # passthrough video
  VCODEC_OPTIONS+=( "-c:v" "copy")
fi

  # always convert type if more than 2ch audio or if not aac/mp3
if [ "$O_ACHANNELS" -gt 2 ] || [ "$O_ACODEC" != "aac" -a "$O_ACODEC" != "mp3" ] ; then
  # convert audio
  ACODEC_OPTIONS+=("-c:a" "aac")
  ACODEC_OPTIONS+=("-b:a" "96k")
  ACODEC_OPTIONS+=("-ar" "44100")
  ACODEC_OPTIONS+=("-ac" "2")
else
  # passthrough audio
  ACODEC_OPTIONS+=("-c:a" "copy")
fi

EXTENSION="${1##*.}"
OUT_PREFIX="${1%.${EXTENSION}}"

if [ "$EXTENSION" == "mkv" ] ; then
  OUTFILE="${OUT_PREFIX}(1).mkv"
else
  OUTFILE="${OUT_PREFIX}.mkv"
fi


ffmpeg -hide_banner -i "$1" "${VCODEC_OPTIONS[@]}" "${ACODEC_OPTIONS[@]}" "${REMAP_OPTIONS[@]}" "$OUTFILE"

