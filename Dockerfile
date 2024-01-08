# Build Asterisk
FROM centos:7 as build-astconv
WORKDIR /app
RUN yum update -y && yum install -y wget
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-1.8.9.3.tar.gz
RUN tar xvf asterisk-1.8.9.3.tar.gz
WORKDIR /app/asterisk-1.8.9.3
RUN yum install -y gcc gcc-c++ make libedit-devel libuuid-devel jansson-devel libxml2-devel sqlite-devel
RUN ./configure
RUN make
# build astconv
RUN yum install -y git
RUN git clone https://github.com/arkadijs/asterisk-g72x
RUN yum install -y gcc libtool glibc-devel
RUN gcc -o astconv asterisk-g72x/astconv.c -I./include -D_GNU_SOURCE -ldl -lm -O2 -s -rdynamic -Wall
RUN mkdir /output
RUN cp astconv /output/
# get G.729 and G.723.1 codecs
RUN wget -O /output/codec_g729.so http://asterisk.hosting.lv/bin/codec_g729-ast18-icc-glibc-x86_64-pentium4.so
RUN wget -O /output/codec_g723.so http://asterisk.hosting.lv/bin/codec_g723-ast18-gcc4-glibc-x86_64-pentium4.so
RUN chmod +x /output/*.so

# final stage
FROM ghcr.io/linuxserver/ffmpeg:latest

# Add files from build stages
COPY --from=build-astconv /output/astconv /usr/local/bin/
COPY --from=build-astconv /output/*.so /usr/lib/

# addd sox
RUN \
  echo "**** install runtime ****" && \
    apt-get update && \
    apt-get install -y \
    sox && \
  echo "**** clean up ****" && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
    
# Reset the ENTRYPOINT
ENTRYPOINT []