#!/bin/bash

mode=$1

if [[ "$mode" == "error" ]]; then
    /opt/xo_dc/ssds/ssds -e \
	| grep -v 'Mounting as exfat' \
	| grep 'Creating mount point' \
	| grep -v '└─' \
	| awk -F " |:" '{printf "%s %s %s %s:%s %s %s\n",$1,$2,$3,$4,$5,$9,$12}' \
	| uniq \
	| awk -F '/' '{print $1,$4}' \
	| grep -E 'ssd_Extreme|ssd_Pro|ssd_part|ssd_SSD' \
	| sed 's/DC,/Data-Centre:/g' \
	| uniq -cif 5
else
    /opt/xo_dc/ssds/ssds -e \
	| grep -v 'Mounting as exfat' \
	| grep 'Creating mount point' \
	| grep -v '└─' \
	| awk -F " |:" '{printf "%s %s %s %s:%s %s %s\n",$1,$2,$3,$4,$5,$9,$12}' \
	| uniq \
	| awk -F '/' '{print $1,$4}' \
	| grep -Ev 'ssd_Extreme|ssd_Pro|ssd_part|ssd_SSD' \
	| sed 's/DC,/Data-Centre:/g' \
	| uniq -cif 5
	# | sed 's/ssd_Extreme/ssd_[LABEL NOT DETECTED]/g' \
	# | grep -Ev 'sd_Extremewk -F '/' '{print $1,$4}' \
fi
