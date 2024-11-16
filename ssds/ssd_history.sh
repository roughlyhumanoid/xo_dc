#!/bin/bash
/opt/xo_dc/ssds/ssds -e \
	| grep -v 'Mounting as exfat' \
	| grep 'Creating mount point' \
	| grep -v '└─' \
	| awk -F " |:" '{printf "%s %s %s %s:%s %s %s\n",$1,$2,$3,$4,$5,$9,$12}' \
	| uniq \
	| awk -F '/' '{print $1,$4}' \
	| sed 's/DC,/Data-Centre:/g'
