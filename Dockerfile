FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get dist-upgrade -y --auto-remove

# install base build requirements
RUN apt-get install -y build-essential file lynx pkg-config wget

# install makemkv-specific build requirements
RUN apt-get install -y --no-install-recommends libavcodec-dev libexpat1-dev libssl-dev zlib1g-dev

ARG MAKEMKV_VERSION
RUN wget -q -O - http://www.makemkv.com/download/old/makemkv-oss-${MAKEMKV_VERSION}.tar.gz | tar xz
RUN wget -q -O - http://www.makemkv.com/download/old/makemkv-bin-${MAKEMKV_VERSION}.tar.gz | tar xz

# Build makemkv
WORKDIR /makemkv-oss-${MAKEMKV_VERSION}/
RUN ./configure --disable-gui && make

WORKDIR /makemkv-bin-${MAKEMKV_VERSION}/
RUN mkdir tmp && echo accepted > tmp/eula_accepted
RUN mkdir -p /root/.MakeMKV
RUN lynx -dump 'https://www.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -A1 'Select all' | tail -1 | awk '{print "app_Key = \"" $1 "\""}' > /root/.MakeMKV/settings.conf

# fetch and extract this in builder
WORKDIR /
RUN wget -q -O - https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar xJ

FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends dvd+rw-tools eject && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /makemkv/oss /makemkv/bin /root/.MakeMKV

COPY --from=builder /root/.MakeMKV/settings.conf /root/.MakeMKV/settings.conf

ARG MAKEMKV_VERSION
COPY --from=builder /makemkv-oss-${MAKEMKV_VERSION}/ /makemkv/oss/

# makemkv requires libssl, libavcodec and libexpat
RUN apt-get update && apt-get install -y --no-install-recommends libavcodec-extra libexpat1 libssl1.1 make && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN make -C /makemkv/oss install

COPY --from=builder /makemkv-bin-${MAKEMKV_VERSION}/ /makemkv/bin/
RUN make -C /makemkv/bin install
RUN rm -r /makemkv && apt-get purge -y --auto-remove make

COPY --from=builder /ffmpeg-4.3.1-amd64-static/ffmpeg /ffmpeg-4.3.1-amd64-static/ffprobe /usr/local/bin/

COPY ripper.sh /

CMD ["/ripper.sh"]
