#!/bin/sh

### check for necessary tools
TOOL_LIST="xmessage mplayer"
for TOOL in $TOOL_LIST; do
    if [ -z $(which $TOOL) ]; then
        echo "$TOOL not found, please install."
        echo "Check README for further informations."
        exit 1
    fi
done

# stream configuration:
#   %d = hall    (1-4)
#   %s = quality (hd, sd)
HLS_URL_TEMPLATE=http://cdn.c3voc.de/hls/s%d_native_%s.m3u8
WEBM_URL_TEMPLATE=http://cdn.c3voc.de/s%d_native_%s.webm

# mplayer options
MPLAYER_OPTS="-cache 4096"

# Fahrplan URL
FAHRPLAN=https://fahrplan.events.ccc.de/congress/2016/Fahrplan/schedule.xml
FAHRPLAN_SZ=https://frab.das-sendezentrum.de/en/33c3/public/schedule.xml

if [ -z "${QUALITY}" ]; then
    QUALITY=hd
    export QUALITY
fi

if [ -z "${STREAM_TYPE}" ] ; then
    STREAM_TYPE=webm
    export STREAM_TYPE
fi

# whereami? (with fallback)
MYPATH=/home/congress
[ -d ${MYPATH} ] || MYPATH=.

######################################################################

# try to get current schedule, otherwise work with old copy or fail
wget --timeout 5 -qO${MYPATH}/schedule.new ${FAHRPLAN}
if [ -s ${MYPATH}/schedule.new ]; then
    cp ${MYPATH}/schedule.new ${MYPATH}/schedule
fi
if [ ! -s ${MYPATH}/schedule ]; then
    echo "Unable to update schedule and no cached version present. I'm sorry."
    exit 1
fi

# try to get current Sendezentrum schedule, otherwise work with old copy or just ignore
wget --timeout 5 -qO${MYPATH}/schedule_sz.new ${FAHRPLAN_SZ}
if [ -s ${MYPATH}/schedule_sz.new ]; then
    cp ${MYPATH}/schedule_sz.new ${MYPATH}/schedule_sz
fi

# shoop da loop
while true; do

    SCHEDULE=$(${MYPATH}/parse_fahrplan.pl)
    TIME=`date +%H:%Mh`
    xmessage -xrm '*international: true' \
        -buttons "Hall 1":1,"Hall 2":2,"Hall G":3,"Hall 6":4,"Sendezentrum":5,\
"set HLS":22,"set WEBM":23,\
"set HD":24,"set SD":25,\
"reload":9,"Quit":0 \
        -default Cancel \
        -center "small script for easy selection of streams from
    33st Chaos Communication Congress

streams available via http://streaming.media.ccc.de/

now: ${TIME}

${SCHEDULE}

stream options: stream_type=${STREAM_TYPE}, quality=${QUALITY}
mplayer options: ${MPLAYER_OPTS}"

    SELECT=$?
    case ${SELECT} in
    [1-5])
        case ${STREAM_TYPE} in
        "hls")
            STREAM_URL=$(printf ${HLS_URL_TEMPLATE} ${SELECT} ${QUALITY})
            ;;
        "webm")
            STREAM_URL=$(printf ${WEBM_URL_TEMPLATE} ${SELECT} ${QUALITY})
            ;;
        esac

        mplayer ${MPLAYER_OPTS} ${STREAM_URL}
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
