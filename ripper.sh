#!/bin/bash

set -x

# tracks need to be at least 1 hour by default
MIN_LENGTH="${MIN_LENGTH:-1000}"
CRF="${CRF:-20}"

TEMP_DIR=/inbound

bluray() {
  # extract disc info
  makemkvcon --cache=100 --minlength=${MIN_LENGTH} --robot info disc:0 > discinfo.txt
  head -20 discinfo.txt

  # extract text metadata
  DISC_LABEL="$(awk -F\" '/^CINFO:32,0,/{print $2}' < discinfo.txt)"
  DISC_DESCRIPTION="$(awk -F\" '/^CINFO:2,0,/{print $2}' < discinfo.txt)"

  CLEAN_DESCRIPTION="$(tr -cd A-Za-z0-9\ <<< \"${DISC_DESCRIPTION}\")"
  echo "$(date) Clean filename would be \"$CLEAN_DESCRIPTION.mkv\""

  # total number of tracks to rip
  TITLE_COUNT="$(awk -F: '/^TCOUNT:/{print $2}' < discinfo.txt)"

  echo "$(date) Started extracting ${TITLE_COUNT} tracks from ${DISC_LABEL} for ${DISC_DESCRIPTION}"

  OUTBOUND_PREFIX="/outbound/${DISC_LABEL}"
  mkdir -p "${OUTBOUND_PREFIX}"
  #cp discinfo.txt "${OUTBOUND_PREFIX}"

  MKV_FILE="$(awk -F\" "/^TINFO:0,27,/{print \$2}" < discinfo.txt)"
  TITLE_DURATION="$(awk -F\" "/^TINFO:0,9,/{print \$2}" < discinfo.txt)"
  INBOUND_FILE="${TEMP_DIR}/${MKV_FILE}"
  OUTBOUND_FILE="${OUTBOUND_PREFIX}/${CLEAN_DESCRIPTION}.mkv"

  echo ""
  echo "extracting title 0 (${TITLE_DURATION}) to ${OUTBOUND_FILE}"
  echo ""
  makemkvcon --cache=1024 --minlength=${MIN_LENGTH} --decrypt --progress=-same mkv disc:0 0 "${TEMP_DIR}"

  # TODO: put this back in when we're not doing raw rips anymore
  # CROP_FACTOR="$( ffmpeg -ss 314 -i "${INBOUND_FILE}" -t 314 -vf cropdetect -map 0:0 -f null - 2>&1 | awk '/Parsed_cropdetect/{print $14}' | tail -1 )"
  # ffmpeg -hide_banner -i "${INBOUND_FILE}" -c:v libx265 -crf $CRF -level 4.1 -aq-mode 3 -aq-strength 0.8 -psy-rd 0.8:0:0 -deblock -3:-3 -vf "${CROP_FACTOR}" -c:a eac3 -b:a 640k -map 0:0 -map 0:1 -map_metadata -1 -metadata:s:a:0 language=eng -metadata:s:v:0 language=eng -preset slower "${OUTBOUND_FILE}"
  ffmpeg -hide_banner -i "${INBOUND_FILE}" -c:v copy -c:a copy -c:s copy -movflags +faststart -map_metadata -1 -metadata:s:a:0 language=eng -metadata:s:s:0 language=eng -map 0:v:0 -map 0:a:0 -map 0:s:0? -async 1 -vsync 1 "${OUTBOUND_FILE}"
  rm "${INBOUND_FILE}"
}

dvd() {
  echo "DVD ripping is not supported directly, use shell to work around"
}

eject -t /dev/sr0

sleep 5
while ! eject -X /dev/sr0 ; do
  sleep 5
done

DISC_TYPE="$(dvd+rw-mediainfo /dev/sr0 | awk '/Mounted Media:/{print $4}')"

echo "Attempting identification for ${DISC_TYPE}"

if [ "${DISC_TYPE}" = "BD-ROM" ]; then
  bluray
elif [ "${DISC_TYPE}" = "DVD-ROM" ] ; then
  dvd
elif [ "${DISC_TYPE}" = "DVD+R" ] ; then
  dvd
else
  echo "Unknown media type ${DISC_TYPE}"
  echo "This may help?"
  dvd+rw-mediainfo /dev/sr0
fi


sync
chown -R ${UID:-1000}:${GID:-1001} "${OUTBOUND_PREFIX}"

echo "$(date) Finished disc "
eject /dev/sr0

