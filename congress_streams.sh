#!/bin/sh



# - - - - >8 - - - - - configure here - - - - >8 - - - - -

# TODO: extract title from fahrplan JSON
TITLE="Remote Chaos Experience"

# stream configuration:
#   %d = rc      (1-2)
#   %s = quality (hd, sd)
HLS_URL_TEMPLATE=https://cdn.c3voc.de/hls/%s_native_%s.m3u8
WEBM_URL_TEMPLATE=https://cdn.c3voc.de/%s_native_%s.webm

# Fahrplan URL
FAHRPLAN=https://fahrplan.events.ccc.de/congress/2023/fahrplan/schedule.json

STREAMS="rc1 rc2 bw:bitwaescherei c-b:cbase cs-h:csh ct-sg:chaostrawler cz-tv:chaoszone cw-tv:cwtv2 f.n:franconiannet a-f:hacc kw:kreaturworks oio r3s rr:restrealitaet sz:sendezentrum wp:wikipaka xh:xhain ib:infobeamer cl:classics"

# - - - - 8< - - - - - configure here - - - - 8< - - - - -


play_stream()
{
    STREAM_ID="$1"

    case ${STREAM_TYPE} in
        "hls")
	    TEMPLATE="${HLS_URL_TEMPLATE}"
            ;;
        "webm")
            TEMPLATE="${WEBM_URL_TEMPLATE}"
            ;;
    esac

    STREAM_URL=$(printf "${TEMPLATE}" "${STREAM_ID}" "${QUALITY}")
    "${PLAYER}" ${PLAYER_OPTIONS} "${STREAM_URL}"
}

set_stream_details()
{
    STREAM="$1"

    STREAM_NAME="${1%:*}"
    STREAM_ID="${1#*:}"
}

set_stream_by_id()
{
    ID="$1"

    set -- ${STREAMS}

    if [ "${ID}" -gt "${START_ID}" ]; then
	shift $(( ID - START_ID ))
    fi

    set_stream_details "$1"
}


### check for necessary tools
TOOL_LIST="xmessage"
for TOOL in ${TOOL_LIST}; do
    if ! command -v "$TOOL" >/dev/null; then
        echo "$TOOL not found, please install."
        echo "Check README for further informations."
        exit 1
    fi
done

# This number is in kilobytes
CACHE=4096
PLAYERS="mpv mplayer"
for P in ${PLAYERS}; do
    if command -v "${P}" >/dev/null; then
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

if [ -z "${QUALITY}" ]; then
    QUALITY=hd
    export QUALITY
fi

if [ -z "${STREAM_TYPE}" ] ; then
    STREAM_TYPE=webm
    export STREAM_TYPE
fi

# whereami? (with fallback)
MYPATH=$(dirname "$0")
[ -d "${MYPATH}" ] || MYPATH=.

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

# precalculate button configuration
BUTTONS=""
START_ID=11
ID=${START_ID}
for STREAM in ${STREAMS}; do
    set_stream_details "${STREAM}"
    BUTTONS="${BUTTONS}${STREAM_NAME}:${ID},"
    ID=$(( ID + 1 ))
done
BUTTONS="${BUTTONS}set HLS:2,set WEBM:3,set HD:4,set SD:5,reload:9,Quit:0"

# shoop da loop
while true; do
    if [ -e schedule_sz ]; then
	SCHEDULE=$(${MYPATH}/parse_fahrplan.pl schedule schedule_sz)
    else
	SCHEDULE=$(${MYPATH}/parse_fahrplan.pl schedule)
    fi
    TIME=$(date +%H:%Mh)
    xmessage -xrm '*international: true' \
             -buttons "$BUTTONS" \
        -default Cancel \
        -center "small script for easy selection of streams from
    $TITLE

streams available via http://streaming.media.ccc.de/

now: ${TIME}

${SCHEDULE}

stream options: stream_type=${STREAM_TYPE}, quality=${QUALITY}
player: ${PLAYER}
player options: ${PLAYER_OPTIONS}"

    SELECT=${?}
    case ${SELECT} in
	0)
            exit 0
            ;;
	1)
            # Window was closed
            exit 0
            ;;
	2)
            STREAM_TYPE=hls
            ;;
	3)
            STREAM_TYPE=webm
            ;;
	4)
            QUALITY=hd;
            ;;
	5)
            QUALITY=sd;
            ;;
	9)
	    exec "${MYPATH}"/congress_streams.sh
	    ;;
	*)
	    set_stream_by_id ${SELECT}
	    play_stream "${STREAM_ID}"
	    ;;
    esac

done
