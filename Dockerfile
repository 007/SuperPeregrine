FROM ubuntu:18.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG MAKEMKV_VERSION=1.14.5
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get dist-upgrade -y --auto-remove

RUN apt-get install -y build-essential file libavcodec-dev libc6-dev libexpat1-dev libgl1-mesa-dev libqt4-dev libssl-dev lynx pkg-config wget zlib1g-dev

RUN wget -q -O - http://www.makemkv.com/download/makemkv-oss-${MAKEMKV_VERSION}.tar.gz | tar xz
RUN wget -q -O - http://www.makemkv.com/download/makemkv-bin-${MAKEMKV_VERSION}.tar.gz | tar xz

WORKDIR /makemkv-oss-${MAKEMKV_VERSION}/
RUN ./configure && make

WORKDIR /makemkv-bin-${MAKEMKV_VERSION}/
RUN mkdir tmp && echo accepted > tmp/eula_accepted
RUN wget -q -O handbrake.deb http://ppa.launchpad.net/stebbins/handbrake-releases/ubuntu/pool/main/h/handbrake/handbrake-cli_1.2.1-zhb-1ppa1~bionic1_amd64.deb
RUN wget -q -O libdvdcss2.deb http://download.videolan.org/pub/ubuntu/stable/libdvdcss2_1.2.13-0_amd64.deb
RUN mkdir -p /root/.MakeMKV
RUN lynx -dump 'https://www.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -A1 'Select all' | tail -1 | awk '{print "app_Key = \"" $1 "\""}' > /root/.MakeMKV/settings.conf

FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
# makemkv requires libssl, libavcodec and libexpat. adding libdvd-pkg for CSS decryption
RUN apt-get update && apt-get install -y --no-install-recommends dvd+rw-tools eject handbrake-cli libavcodec57 libexpat1 libssl1.1 make

RUN mkdir -p /makemkv/oss /makemkv/bin /root/.MakeMKV

COPY --from=builder /root/.MakeMKV/settings.conf /root/.MakeMKV/settings.conf
ARG MAKEMKV_VERSION=1.14.5

COPY --from=builder /makemkv-oss-${MAKEMKV_VERSION}/ /makemkv/oss/
RUN cd /makemkv/oss && make install

COPY --from=builder /makemkv-bin-${MAKEMKV_VERSION}/ /makemkv/bin/
RUN cd /makemkv/bin && make install
RUN dpkg -i /makemkv/bin/handbrake.deb
RUN dpkg -i /makemkv/bin/libdvdcss2.deb
RUN rm -r /makemkv

COPY ripper.sh /

CMD "/ripper.sh"
