#!/bin/bash

PRESET_FILE="${PRESET_FILE:-preset.json}"
PRESET_NAME="${PRESET_NAME:-preset}"

# tracks need to be at least 16 minutes 40 seconds
MIN_LENGTH=1000

# extract disc info
makemkvcon --cache=1 --minlength=${MIN_LENGTH} --robot info disc:0 > discinfo.txt

# extract text metadata
DISC_LABEL="$(awk -F, '/^CINFO:32,0,/{print $3}' < discinfo.txt | sed 's/"//g')"
DISC_DESCRIPTION="$(awk -F, '/^CINFO:2,0,/{print $3}' < discinfo.txt | sed 's/"//g')"

# total number of tracks to rip
TITLE_COUNT="$(awk -F: '/^TCOUNT:/{print $2}' < discinfo.txt)"

# file being encoded for step N-1
LAST_FILE="/inbound/last_file"

echo "$(date) Started extracting ${TITLE_COUNT} tracks from ${DISC_LABEL} for ${DISC_DESCRIPTION}"
echo "$(date) Using ${PRESET_NAME} from ${PRESET_FILE} for encoding"

# extract raw from disk for track N while re-encoding N-1
for TITLE in $(seq 0 $((TITLE_COUNT - 1))); do
  MKV_FILE="$(awk -F, "/^TINFO:${TITLE},27/{print \$4}" < discinfo.txt | sed 's/"//g' )"
  INBOUND_FILE="/inbound/${MKV_FILE}"
  OUTBOUND_FILE="/outbound/${MKV_FILE%.mkv}.mp4"
  #makemkvcon --cache=1024 --minlength=${MIN_LENGTH} --decrypt --robot --progress=-same mkv disc:0 ${TITLE} /inbound
  makemkvcon --cache=1024 --minlength=${MIN_LENGTH} --decrypt --progress=-same mkv disc:0 ${TITLE} /inbound

  # wait for last encoding to finish so we can clean up and process next one
  wait
  rm "${LAST_FILE}"
  LAST_FILE=${INBOUND_FILE}
  # run this in the background so we can extract next file while it processes
  HandBrakeCLI --preset-import-file /presets/${PRESET_FILE} --preset ${PRESET_NAME} --input "${INBOUND_FILE}" --optimize --output "${OUTBOUND_FILE}" &
  sleep 60
done

# wait for the final encoding to complete
# should this be FG instead?
wait
rm "${LAST_FILE}"

echo "$(date) Finished disc "