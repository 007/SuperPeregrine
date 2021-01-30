#!/bin/bash
# use tor to download from BBC iPlayer
while ! torsocks -i youtube-dl --keep-fragments --no-playlist --abort-on-error --abort-on-unavailable-fragment --no-overwrites "$@"; do
  sleep 5
  date
done

