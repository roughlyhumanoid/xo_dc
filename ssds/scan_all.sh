#!/bin/bash
ssd_cmd=/opt/xo_dc/ssds/ssds
# readarray -t all_ssds <<< $(/opt/xo_dc/ssds/ssds -q -l)
readarray -t all_ssds <<< $("$ssd_cmd" -q -l)
ns="${#all_ssds[@]}"
scan_all_log=/var/log/xocean_data_centre/scan_all.log
scan_all_tight=/var/log/xocean_data_centre/scan_all_summary.log
# ns=1

for (( i=0; i<$ns; i++ )); do 
	ssd="${all_ssds[$i]}"
	printf "ssd_%s\tScanning\n" "$ssd" | /usr/bin/ts
	"$ssd_cmd" -s "$ssd" | /usr/bin/ts "%b %d %H:%M:%S %s" | /usr/bin/tee -a "$scan_all_log" 2>&1 | grep -E 'xodc files|S3:' | /usr/bin/tee -a "$scan_all_tight"
done
