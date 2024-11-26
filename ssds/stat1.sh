#!/bin/bash
mode=$1
hour=$2

log_dir="/var/log/xocean_data_centre"
report_base="summary_report_01"

# If print mode
if [[ "$mode" == "print" ]]; then
	# Just show report
	fn=$(ls -1tr ${log_dir}/${report_base}*.log | tail -n 1)
	date_mod=$(/usr/bin/stat --format %y "$fn")
	printf "### NOTE - This summary may be up to 1 hour old! ###\n"
	printf "Updated at: %s\n" "$date_mod"
	printf "This updated stored at %s\n\n" "${fn}"
	cat "${fn}"
	exit 0
fi

# Otherwise
tf=$(mktemp)
/opt/xo_dc/ssds/ssds -q -l > "$tf"
readarray -t ssds <<< $(cat "$tf")
ns="${#ssds[@]}"
dt=$(date +'%Y-%m-%d-%H00')
stat1_file="${log_dir}/${report_base}_${dt}.log"
printf "Writing output to: %s\n" "$stat1_file"

# Write report
printf "### SSD summary - DC1 xodc ( ServerChoice Stevanage, transfer node server ) ###\n" > "$stat1_file"
/opt/xo_dc/ssds/clear_ssd.sh -H | /usr/bin/ts >> "$stat1_file" 2> "${stat1_file}.err"
/opt/xo_dc/ssds/clear_ssd.sh -H | sed -e 's/[a-zA-Z0-9:%()]/-/g' | /usr/bin/ts >> "$stat1_file" 2> "${stat1_file}.err"

for (( i=0; i<"$ns"; i++ )); do
	this_ssd="${ssds[$i]}"
	nprocs=$(ps -ef | grep -i 'clear_ssd.sh 422' | grep -v 'grep' | wc -l)

	if [[ "$nprocs" -eq 0 ]]; then
		printf "Adding stat1 info for %s\n" "${this_ssd}"
		/opt/xo_dc/ssds/clear_ssd.sh "${this_ssd}" 208 -o -q | grep -i size | /usr/bin/ts >> "$stat1_file" 2> "${stat1_file}.err"
	else
		printf "Already running for %s\n" "${this_ssd}"
	fi
done

