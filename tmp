# ffmpeg - http://ffmpeg.org/download.html
# based on image from 
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
#
FROM        alpine:3.4


ENV         X264_VERSION=20160826-2245-stable \
            PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
            SRC=/usr/local

COPY ism_movenc.patch /root/ism_movenc.patch

RUN     buildDeps="autoconf \
                   automake \
                   bash \
                   binutils \
                   bzip2 \
                   cmake \
                   curl \
                   coreutils \
                   g++ \
                   gcc \
                   git \
                   libtool \
                   make \
                   openssl-dev \
                   tar \
                   yasm \
                   zlib-dev" && \
        export MAKEFLAGS="-j$(($(grep -c ^processor /proc/cpuinfo) + 1))" && \
        apk  add --update ${buildDeps} freetype-dev fontconfig-dev ttf-droid libgcc libstdc++ ca-certificates && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-pic --enable-shared --disable-cli && \
        make && \
        make install && \
        rm -rf ${DIR}


## ffmpeg source from github
RUN     DIR=$(mktemp -d) && cd ${DIR} && \
        git clone https://github.com/FFmpeg/FFmpeg.git . && \
        git checkout -b ism_build cf3d2d52b59ddfc2a7c65a8e66f7698c4b837e51 && \
        git apply /root/ism_movenc.patch && \
        ./configure --prefix="${SRC}" \
        --extra-cflags="-I${SRC}/include" \
        --extra-ldflags="-L${SRC}/lib" \
        --bindir="${SRC}/bin" \
        --disable-doc \
        --disable-static \
        --enable-shared \
        --disable-ffplay \
        --extra-libs=-ldl \
        --enable-version3 \
        --enable-libx264 \
        --enable-libfontconfig \
        --enable-libfreetype \
        --enable-gpl \
        --enable-avresample \
        --enable-postproc \
        --enable-nonfree \
        --disable-debug \
        --enable-openssl && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        rm -rf ${DIR} && \
        cd && \
        apk del ${buildDeps} && \
        rm -rf /var/cache/apk/* /usr/local/include && \
        ffmpeg -buildconf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD  ffmpeg -re -f lavfi -i smptehdbars=size=1280x720 \
            -i "https://raw.githubusercontent.com/unifiedstreaming/live-demo/master/ffmpeg/usp_logo_white.png" \
            -filter_complex \
                "sine=frequency=1:beep_factor=480:sample_rate=48000, \
                atempo=0.5[a1]; \
                sine=frequency=1:beep_factor=960:sample_rate=48000, \
                atempo=0.5, \
                adelay=1000[a2]; \
                [a1][a2]amix, \
                highpass=40, \
                adelay=$(date +%3N), \
                asplit=2[a1][a2]; \
                [a1]showwaves=mode=p2p:colors=white:size=1280x100:scale=lin:rate=$(($FRAME_RATE))[waves]; \
                color=size=1280x100:color=black[blackbg]; \
                [blackbg][waves]overlay[waves2]; \
                [0][waves2]overlay=y=620[v]; \
                [v]drawbox=y=25: x=iw/2-iw/7: c=0x00000000@1: w=iw/3.5: h=36: t=max, \
                drawtext=text='FFMPEG Enc 2 - 1000k AVC @25fps': fontsize=32: x=(w-text_w)/2: y=125: fontsize=32: fontcolor=white, \
                drawtext=timecode_rate=${FRAME_RATE}: timecode='$(date -u +%H\\:%M\\:%S)\\${FRAME_SEP}$(($(date +%3N)/$((1000/$FRAME_RATE))))': tc24hmax=1: fontsize=32: x=(w-tw)/2+tw/2: y=30: fontcolor=white, \
                drawtext=text='%{gmtime\:%Y-%m-%d}\ ': fontsize=32: x=(w-tw)/2-tw/2: y=30: fontcolor=white[v+tc]; \
                [v+tc][1]overlay=eval=init:x=W-15-w:y=15[vid]" \
            -g $GOP_LENGTH \
            -r $FRAME_RATE \
            -keyint_min $GOP_LENGTH \
            -c:v libx264 -b:v 1000k -profile:v main -preset ultrafast -tune zerolatency \
            -c:a aac -b:a 128k -ar 48000 -metadata:s:a:0 language=eng \
            -map "[vid]" \
            -map "[a2]" \
            -fflags +genpts \
            -movflags isml+frag_keyframe \
            -ism_offset $(($(date +%s)*10000000)) \
            -f ismv \
            $PUB_POINT_URI