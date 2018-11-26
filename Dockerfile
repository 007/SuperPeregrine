FROM ubuntu:18.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG MAKEMKV_VERSION=1.14.1
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get dist-upgrade -y --auto-remove

RUN apt-get install -y build-essential curl file libavcodec-dev libc6-dev libexpat1-dev libgl1-mesa-dev libqt4-dev libssl-dev lynx pkg-config zlib1g-dev

RUN curl -s http://www.makemkv.com/download/makemkv-oss-${MAKEMKV_VERSION}.tar.gz | tar xz
RUN curl -s http://www.makemkv.com/download/makemkv-bin-${MAKEMKV_VERSION}.tar.gz | tar xz

WORKDIR /makemkv-oss-${MAKEMKV_VERSION}/
RUN ./configure && make

WORKDIR /makemkv-bin-${MAKEMKV_VERSION}/
RUN mkdir tmp && echo accepted > tmp/eula_accepted
RUN curl -s http://ppa.launchpad.net/stebbins/handbrake-releases/ubuntu/pool/main/h/handbrake/handbrake-cli_1.1.2-zhb-1ppa1~bionic1_amd64.deb > handbrake.deb

RUN mkdir -p /root/.MakeMKV
RUN lynx -dump 'https://www.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -A1 'Select all' | tail -1 | awk '{print "app_Key = \"" $1 "\""}' > /root/.MakeMKV/settings.conf

FROM ubuntu:18.04
# makemkv requires libssl, libavcodec and libexpat
RUN apt-get update && apt-get install -y --no-install-recommends dvd+rw-tools handbrake-cli libavcodec57 libexpat1 libssl1.1 make

RUN mkdir -p /makemkv/oss /makemkv/bin /root/.MakeMKV

COPY --from=builder /root/.MakeMKV/settings.conf /root/.MakeMKV/settings.conf
ARG MAKEMKV_VERSION=1.14.1

COPY --from=builder /makemkv-oss-${MAKEMKV_VERSION}/ /makemkv/oss/
RUN cd /makemkv/oss && make install

COPY --from=builder /makemkv-bin-${MAKEMKV_VERSION}/ /makemkv/bin/
RUN cd /makemkv/bin && make install
RUN dpkg -i /makemkv/bin/handbrake.deb
RUN rm -r /makemkv

COPY ripper.sh /

CMD "/ripper.sh"
