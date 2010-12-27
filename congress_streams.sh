#!/bin/bash

######################################################################

# stream URL configuration be here
STREAM_BASE=http://wmv.27c3.fem-net.de
STREAM_1=${STREAM_BASE}/saal1
STREAM_2=${STREAM_BASE}/saal2
STREAM_3=${STREAM_BASE}/saal3

# Fahrplan URL
FAHRPLAN=http://events.ccc.de/congress/2010/Fahrplan/schedule.de.xml

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
    xmessage -buttons "Saal 1":1,"Saal 2":2,"Saal 3":3,"reload":9,"Quit":0 \
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

	2)
	    mplayer ${MPLAYER_OPTS} ${STREAM_2}
	    ;;
	3)
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
