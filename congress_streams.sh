#!/bin/bash

######################################################################

# stream URL configuration be here
# official streams as statde here: https://events.ccc.de/congress/2012/wiki/Streaming
STREAM_BASE=http://wmv.29c3.fem-net.de
STREAM_1=${STREAM_BASE}/saal1
STREAM_2=${STREAM_BASE}/saal4
STREAM_3=${STREAM_BASE}/saal6

# Fahrplan URL
FAHRPLAN=http://events.ccc.de/congress/2012/Fahrplan/schedule.de.xml

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
    TIME=`date +%H:%M`
    xmessage -buttons "Saal 1":1,"Saal 4":4,"Saal 6":6,"reload":9,"Quit":0 \
        -default Cancel \
        -center "Miniauswahlskript fuer die Streams vom
Chaos Communication Congress.

Uhrzeit: ${TIME}

${SCHEDULE}

mplayer options: ${MPLAYER_OPTS}"

    case $? in
	1)
	    mplayer ${MPLAYER_OPTS} ${STREAM_1}
	    ;;

	4)
	    mplayer ${MPLAYER_OPTS} ${STREAM_2}
	    ;;
	6)
	    mplayer ${MPLAYER_OPTS} ${STREAM_3}
	    ;;
	9)
	    exec ${MYPATH}/congress_streams.sh
	    ;;
	0)
	    exit 0
	    ;;
    esac

done
