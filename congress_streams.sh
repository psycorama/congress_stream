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

HLS_BASE=http://cdn.c3voc.de/hls/
WEBM_BASE=http://cdn.c3voc.de/

if [ -z "$QUALITY" ]; then
    QUALITY=hd
    export QUALITY
fi

if [ -z "$STREAM_TYPE" ] ; then
    STREAM_TYPE=webm
    export STREAM_TYPE
fi

# Fahrplan URL
FAHRPLAN=https://events.ccc.de/congress/2015/Fahrplan/schedule.xml

# mplayer options
MPLAYER_OPTS="-cache 4096"

# whereami? (with fallback)
MYPATH=/home/congress
[ -d ${MYPATH} ] || MYPATH=./

######################################################################

# get current schedule
wget -qO${MYPATH}/schedule ${FAHRPLAN}

# shoop da loop
while true; do

    SCHEDULE=$(${MYPATH}/parse_fahrplan.pl)
    TIME=`date +%H:%Mh`
    xmessage -xrm '*international: true' \
        -buttons "Hall 1":1,"Hall 2":2,"Hall G":3,"Hall 6":4,\
"set HLS":22,"set WEBM":23,\
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
