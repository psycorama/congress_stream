#!/bin/sh

### check for necessary tools
TOOL_LIST="xmessage"
for TOOL in ${TOOL_LIST}; do
    if [ -z "$(which $TOOL)" ]; then
        echo "$TOOL not found, please install."
        echo "Check README for further informations."
        exit 1
    fi
done

# This number is in kilobytes
CACHE=4096
PLAYERS="mpv mplayer"
for P in ${PLAYERS}; do
    if [ -n "$(which ${P})" ]; then
        PLAYER=${P}
        break
    fi
done
if [ -z "${PLAYER}" ]; then
    echo "No player found, install one of ${PLAYERS}"
    exit 1
fi

PLAYER_OPTIONS=""
case ${PLAYER} in
    "mpv")
        PLAYER_OPTIONS="--cache --demuxer-max-bytes=${CACHE}KiB --no-ytdl"
        ;;
    "mplayer")
        PLAYER_OPTIONS="-cache ${CACHE}"
        ;;
esac
echo "Using ${PLAYER} wit options ${PLAYER_OPTIONS}"

# stream configuration:
#   %d = rc      (1-2)
#   %s = quality (hd, sd)
HLS_URL_TEMPLATE=https://cdn.c3voc.de/hls/rc%d_native_%s.m3u8
WEBM_URL_TEMPLATE=https://cdn.c3voc.de/rc%d_native_%s.webm

# Fahrplan URL
FAHRPLAN=https://fahrplan.events.ccc.de/rc3/2020/Fahrplan/schedule.xml
#FAHRPLAN_SZ=https://frab.das-sendezentrum.de/en/35c3/public/schedule.xml

if [ -z "${QUALITY}" ]; then
    QUALITY=hd
    export QUALITY
fi

if [ -z "${STREAM_TYPE}" ] ; then
    STREAM_TYPE=webm
    export STREAM_TYPE
fi

# whereami? (with fallback)
MYPATH=$(dirname $0)
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
# wget --timeout 5 -qO${MYPATH}/schedule_sz.new ${FAHRPLAN_SZ}
# if [ -s ${MYPATH}/schedule_sz.new ]; then
#     cp ${MYPATH}/schedule_sz.new ${MYPATH}/schedule_sz
# fi

# shoop da loop
while true; do

    SCHEDULE=$(${MYPATH}/parse_fahrplan.pl)
    TIME=$(date +%H:%Mh)
    xmessage -xrm '*international: true' \
        -buttons "rC1":11,"rC2":12,\
"set HLS":22,"set WEBM":23,\
"set HD":24,"set SD":25,\
"reload":9,"Quit":0 \
        -default Cancel \
        -center "small script for easy selection of streams from
    36th Chaos Communication Congress

streams available via http://streaming.media.ccc.de/

now: ${TIME}

${SCHEDULE}

stream options: stream_type=${STREAM_TYPE}, quality=${QUALITY}
player: ${PLAYER}
player options: ${PLAYER_OPTIONS}"

    SELECT=${?}
    case ${SELECT} in
    11|12|13|14|15)
        case ${STREAM_TYPE} in
        "hls")
            STREAM_URL=$(printf ${HLS_URL_TEMPLATE} $((${SELECT}-10)) ${QUALITY})
            ;;
        "webm")
            STREAM_URL=$(printf ${WEBM_URL_TEMPLATE} $((${SELECT}-10)) ${QUALITY})
            ;;
        esac

        ${PLAYER} ${PLAYER_OPTIONS} ${STREAM_URL}
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
    1)
        # Window was closed
        exit 0
        ;;
    esac

done
