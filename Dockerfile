FROM ubuntu:18.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get dist-upgrade -y --auto-remove

RUN apt-get install -y build-essential curl file libavcodec-dev libc6-dev libexpat1-dev libgl1-mesa-dev libqt4-dev libssl-dev pkg-config zlib1g-dev

RUN curl -s http://www.makemkv.com/download/makemkv-oss-1.12.3.tar.gz | tar xz
RUN curl -s http://www.makemkv.com/download/makemkv-bin-1.12.3.tar.gz | tar xz

WORKDIR /makemkv-oss-1.12.3/
RUN ./configure && make

WORKDIR /makemkv-bin-1.12.3/
RUN mkdir tmp && echo accepted > tmp/eula_accepted

FROM ubuntu:18.04
RUN apt-get update && apt-get install -y make

RUN mkdir -p /makemkv/oss /makemkv/bin

COPY --from=builder /makemkv-oss-1.12.3/ /makemkv/oss/
COPY --from=builder /makemkv-bin-1.12.3/ /makemkv/bin/

RUN cd /makemkv/oss && make install
RUN cd /makemkv/bin && make install

RUN rm -r /makemkv

RUN apt-get install -y --no-install-recommends libssl1.1 libavcodec57 libexpat1
