#!/bin/bash

readarray -t ssd_lines <<< $(/opt/xo_dc/ssds/ssds list -v)

na="${#ssd_lines[@]}"
# echo $na

for (( i=0; i<"$na"; i++)); do
	tline="${ssd_lines[$i]}"
	ssd=$(echo $tline | awk '{ print $2 }')
	dev=$(echo $tline | awk '{ print $4 }')
	/usr/sbin/smartctl -H "$dev"
done

exit 0

