FROM ubuntu:18.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get dist-upgrade -y --auto-remove

RUN apt-get install -y build-essential curl file libavcodec-dev libc6-dev libexpat1-dev libgl1-mesa-dev libqt4-dev libssl-dev lynx pkg-config zlib1g-dev

RUN curl -s http://www.makemkv.com/download/makemkv-oss-1.12.3.tar.gz | tar xz
RUN curl -s http://www.makemkv.com/download/makemkv-bin-1.12.3.tar.gz | tar xz

WORKDIR /makemkv-oss-1.12.3/
RUN ./configure && make

WORKDIR /makemkv-bin-1.12.3/
RUN mkdir tmp && echo accepted > tmp/eula_accepted

RUN mkdir -p /root/.MakeMKV
RUN lynx -dump 'https://www.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -A1 'Select all' | tail -1 | awk '{print "app_Key = \"" $1 "\""}' > /root/.MakeMKV/settings.conf

FROM ubuntu:18.04
RUN apt-get update && apt-get install -y --no-install-recommends make libssl1.1 libavcodec57 libexpat1

RUN mkdir -p /makemkv/oss /makemkv/bin /root/.MakeMKV

COPY --from=builder /root/.MakeMKV/settings.conf /root/.MakeMKV/settings.conf

COPY --from=builder /makemkv-oss-1.12.3/ /makemkv/oss/
RUN cd /makemkv/oss && make install

COPY --from=builder /makemkv-bin-1.12.3/ /makemkv/bin/
RUN cd /makemkv/bin && make install

RUN rm -r /makemkv
