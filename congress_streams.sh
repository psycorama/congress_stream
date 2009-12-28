#!/bin/bash

site="http://streaming-26c3-wmv.fem-net.de/saal"

while true; do

PROGRAMM=$(./parse_fahrplan.pl)

xmessage -buttons "Saal 1":1,"Saal 2":2,"Saal 3":3,"reload":9,"Quit":0 \
        -default Cancel \
        -center "Miniauswahlskript fuer die Streams vom
Chaos Communication Congress.

$PROGRAMM

Cache is set for 4MB. Should be enough"

ret=$?

if [ $ret -eq 1 ]; then
    mplayer -cache 4000 $site/saal1
elif [ $ret -eq 2 ]; then
    mplayer -cache 4000 $site/saal2
elif [ $ret -eq 3 ]; then
    mplayer -cache 4000 $site/saal3
elif [ $ret -eq 9 ]; then
        exec /home/congress/26c3.sh
elif [ $ret -eq 0 ]; then
        exit 0;
fi;

done;
