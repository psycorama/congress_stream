#!/bin/bash
# git push test

SITE=http://streaming-26c3-wmv.fem-net.de
MYPATH=/home/congress
[ -d $MYPATH ] || MYPATH=./

wget -qO$MYPATH/schedule http://events.ccc.de/congress/2010/Fahrplan/schedule.de.xml | sed s/00:00/24:00/

while true; do

PROGRAMM=$($MYPATH/parse_fahrplan.pl)
TIME=`date +%H:%M`
xmessage -buttons "Saal 1":1,"Saal 2":2,"Saal 3":3,"reload":9,"Quit":0 \
        -default Cancel \
        -center "Miniauswahlskript fuer die Streams vom
Chaos Communication Congress.

Uhrzeit: $TIME
$PROGRAMM

Cache is set for 4MB. Should be enough"

ret=$?

if [ $ret -eq 1 ]; then
    mplayer -cache 4000 $SITE/saal1
elif [ $ret -eq 2 ]; then
    mplayer -cache 4000 $SITE/saal2
elif [ $ret -eq 3 ]; then
    mplayer -cache 4000 $SITE/saal3
elif [ $ret -eq 9 ]; then
        exec $MYPATH/congress_streams.sh
elif [ $ret -eq 0 ]; then
        exit 0;
fi;

done;
