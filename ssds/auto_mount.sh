#!/bin/bash
tail_log=$1
source /home/xo-mark/scripts/ssd_mounts.sh
log_fp='/var/log/xocean_data_centre/automount.log'
#loop2 | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> /var/log/xocean_data_centre/automount.log 2>&1 
loop2 | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> "${log_fp}"  2>&1 
xrun_pid=$!

if [[ "$tail_log" == "tail" ]]; then
	# /usr/bin/grc /usr/bin/tail -f ${log_fp} --pid=$xrun_pid
	printf "Press CTRL-C to exit.\n\n"
	/usr/bin/grc /usr/bin/tail -f ${log_fp} 
else
	printf "Log written to: %s\n" "$log_fp"
fi
