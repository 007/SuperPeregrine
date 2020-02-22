#!/bin/bash

# TODO: put this logic into the convert.sh script once it's worked out

# # if input is 4k 265:
#   copy as-is
#   scale to 1080/265
#   scale to 720/264

# # if input is 4k 264:
#   scale to 4k/265
#   scale to 1080/265
#   scale to 720/264

# # if input is 1080p:
#   copy as-is
#   scale to 720/264


# 1080p section
BLOCK_SIZE=4
TARGET_W=1280
TARGET_H=720
: \
&& ffmpeg \
  -hide_banner \
  -i sample.mkv \
  -filter_complex "[0:v]split=2[original][resized];[resized]scale='if(gt(iw/${TARGET_W},ih/${TARGET_H}),min(iw,${TARGET_W}),-${BLOCK_SIZE})':'if(gt(iw/${TARGET_W},ih/${TARGET_H}),-${BLOCK_SIZE},min(ih,${TARGET_H}))':flags=lanczos[720p]" \
  -map '[original]' -c:v copy \
  -map '[720p]' -c:v h264 -pix_fmt yuv420p \
  -map 0:a -c:a aac -b:a 96k -ar 44100 -ac 2 \
  -movflags +faststart \
  sample.muxed.mkv
