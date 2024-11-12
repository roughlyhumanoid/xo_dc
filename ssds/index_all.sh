#!/bin/bash
tf=$(mktemp)
/opt/xo_dc/ssds/ssds -q -l > "$tf"

readarray -t ssds <<< $(cat "$tf")
ns="${#ssds[@]}"

for (( i=o; i<$ns; i++ )); do 
	td=$(date +'%Y-%m-%d')
	this_ssd="${ssds[$i]}"
	target="/mnt/usb_drives/ssd_${this_ssd}"
	db="/opt/duc/dbs/full_ssd_${this_ssd}.${td}.db"
	printf "Running on: %s for: %s,  DB: %s, Scanning: %s\n" "$td" "$this_ssd" "$db" "$target"
	/usr/bin/duc index -x --uncompressed -d ${db} ${target}
done	
