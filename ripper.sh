#!/bin/bash

for TITLE in $(seq 0 $(makemkvcon --cache=1024 --minlength=1000 --robot info disc:0 | awk -F: '/^TCOUNT:/{print $2 - 1}')); do
  makemkvcon --cache=1024 --minlength=1000 --decrypt --progress=-same mkv disc:0 ${TITLE} /inbound
done
