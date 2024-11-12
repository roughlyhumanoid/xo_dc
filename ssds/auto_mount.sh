#!/bin/bash
tail_log=$1
log_fp='/var/log/xocean_data_centre/automount.log'
printf "Running as: %s\n" "$(whoami)"
/opt/xo_dc/ssds/auto_mount_sc.sh >> /var/log/xocean_data_centre/automount_alt.log 2>&1 &
xrun_pid=$!

printf "Running with pid: %s\n" "$xrun_pid"

if [[ "$tail_log" == "tail" ]]; then
	printf "Press CTRL-C to exit.\n\n"
	/usr/bin/grc /usr/bin/tail -f ${log_fp} --pid="$xrun_pid"
else
	printf "Log written to: %s\n" "$log_fp"
fi


exit 0
# source /home/xo-mark/scripts/ssd_mounts.sh
# source /opt/xo_dc/ssds/ssd_mounts.sh
# loop2 | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> /var/log/xocean_data_centre/automount.log 2>&1 
# loop2 no_upload | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> "${log_fp}"  2>&1 
	# /usr/bin/grc /usr/bin/tail -f ${log_fp} --pid=$xrun_pid
