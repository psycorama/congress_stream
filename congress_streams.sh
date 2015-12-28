#!/bin/sh

### check for necessary tools
TOOL_LIST="" # nothing here but us chickens!
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

# player and options
PLAYER="mplayer -cache 4096"

# simple RasPi autodetection
if [ $(which omxplayer) ]; then
    PLAYER="omxplayer -o hdmi"
    STREAM_TYPE=hls
else
    if [ -z $(which mplayer) ]; then
    echo "mplayer or omxplayer are needed for this, please install one"
    exit -1;
    fi
fi

# Fahrplan URL
FAHRPLAN=https://events.ccc.de/congress/2015/Fahrplan/schedule.xml
FAHRPLAN_SZ=https://frab.das-sendezentrum.de/en/32c3/public/schedule.xml

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
echo Getting Fahrplan...
wget --timeout 5 --no-verbose --show-progress -O${MYPATH}/schedule.new ${FAHRPLAN}
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

    echo Parsing Fahrplan...
    SCHEDULE=$(${MYPATH}/parse_fahrplan.pl)
    TIME=`date +%H:%Mh`
    cat <<EOF


    small script for easy selection of streams from
    32st Chaos Communication Congress

streams available via http://streaming.media.ccc.de/
EOF
    echo now: ${TIME}
    echo
    echo "${SCHEDULE}"
    echo
    echo stream options: stream_type=${STREAM_TYPE}, quality=${QUALITY}
    echo player options: ${PLAYER}
    cat <<EOF

possible commands:
[1-5]   = Hall 1, Hall 2, Hall G, Hall 6, Sendezentrum
[22,23] = set HLS / WEBM
[24,25] = set HD / SD
[9]     = reload
[0]     = quit
EOF

read SELECT

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

        ${PLAYER} ${MPLAYER_OPTS} ${STREAM_URL}
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
