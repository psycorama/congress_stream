#!/bin/bash

######################################################################

# stream URL configuration be here
# official streams as stated here:
#   https://events.ccc.de/congress/2014/wiki/Streams
#   http://streaming.media.ccc.de/

if [ -z $(which mplayer) ]; then
    echo "mplayer is needed for this, please install one"
    exit -1;
fi

RTMP_BASE=rtmp://rtmp.stream.c3voc.de:1935
HLS_BASE=http://hls.stream.c3voc.de/hls
WEBM_BASE=http://webm.stream.c3voc.de:8000

if [ -z "$QUALITY" ]; then
    QUALITY=hd
    export QUALITY
fi

if [ -z "$STREAM_TYPE" ] ; then
    STREAM_TYPE=webm
    export STREAM_TYPE
fi

# Fahrplan URL
FAHRPLAN=http://events.ccc.de/congress/2014/Fahrplan/schedule.xml

# mplayer options
MPLAYER_OPTS="-cache 4096"

# whereami? (with fallback)
MYPATH=/home/congress
[ -d ${MYPATH} ] || MYPATH=./

######################################################################

# get current schedule
wget -qO${MYPATH}/schedule ${FAHRPLAN} | sed s/00:00/24:00/

# shoop da loop
while true; do

    SCHEDULE=$(${MYPATH}/parse_fahrplan.pl)
    TIME=`date +%H:%Mh`
    xmessage -xrm '*international: true' \
        -buttons "Saal 1":1,"Saal 2":2,"Saal G":3,"Saal 6":4,\
"set RTMP":21,"set HLS":22,"set WEBM":23,\
"set HD":24,"set SD":25,\
"reload":9,"Quit":0 \
        -default Cancel \
        -center "small script for easy selection of streams from
    31st Chaos Communication Congress

streams available via http://streaming.media.ccc.de/

now: ${TIME}

${SCHEDULE}

stream options: stream_type=$STREAM_TYPE, quality=$QUALITY
mplayer options: ${MPLAYER_OPTS}"

    SELECT=$?
    case $SELECT in
    [1-4])
        case $STREAM_TYPE in
        "rtmp")
            STREAM_BASE="${RTMP_BASE}/stream/s"
            STREAM_TAIL="_native_$QUALITY"
            ;;
        "hls")
            STREAM_BASE="${HLS_BASE}/s"
            STREAM_TAIL="_native_$QUALITY.m3u8"
            ;;
        "webm")
            STREAM_BASE="${WEBM_BASE}/s"
            STREAM_TAIL="_native_$QUALITY.webm"
            ;;
        esac

        mplayer ${MPLAYER_OPTS} ${STREAM_BASE}$SELECT$STREAM_TAIL
        ;;
    21)
        STREAM_TYPE=rtmp
        ;;
    22)
        STREAM_TYPE=hls
        ;;
    23)
        STREAM_TYPE=webm
        ;;
    24)
        QUALITY=hd;
        ;;
    25)
        QUALITY=sd;
        ;;
    9)
	    exec ${MYPATH}/congress_streams.sh
	    ;;
    0)
        exit 0
        ;;
    esac


done
