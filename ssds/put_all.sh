#!/bin/bash
s3dc='s3://xocean-production-raw-dc-eu-west-2'
base_dir="/mnt/usb_drives"
pid_file="/usr/var/run/ssd_upload.pid"
ssd=$1
# ssd='428'

set -Eeuo pipefail

notify () {
	FAILED_COMMAND="$(caller): ${BASH_COMMAND}" 
	printf "Failed command: %s\n" "$FAILED_COMMAND"
	rm $pid_file
    # perform notification here
}

# trap notify ERR
# trap notify INT

function upload_ssd()
{
	ssd=$1
	this_ssd="ssd_${ssd}"
	this_source="${base_dir}/${this_ssd}"

	if [[ ! -d "$this_source" ]]; then
		printf "Error.  Directory doesn\'t exist\n\t%s\n" "$this_source"
		find "${base_dir}" -mindepth 1 -maxdepth 1 -type d -exec readlink -e {} \; | sort
		exit 1
	fi

	this_dest="${s3dc}/DC1/${this_ssd}"
	readarray -t source_dirs <<< $(find "${this_source}/" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | grep -Ev 'RECYCLE' | grep -iv 'System Volume')
	n="${#source_dirs[@]}"
	printf "Found %d subdirs suitable for uploading\n" "$n"

	for (( i=0; i<$n; i++ )); do 
		this_dir="${source_dirs[$i]}"
		this_dest_subdir="${this_dest}/${this_dir}"
		printf "Syncing ssd_%s root dir: %s to %s\n" "$ssd" "$this_dir" "$this_dest_subdir"
		this_source_subdir="${this_source}/${this_dir}"
		printf "About to sync...\nFrom:\t%s\nTo:\t%s\n" "$this_source_subdir" "$this_dest_subdir"
	
		aws s3 --profile dc_auto_camera \
			sync "$this_source_subdir" "$this_dest_subdir" 

		#	--dryrun
		# --debug \
	done

	printf "Finished uploading data from: %s\n" "$this_ssd"
}

function upload_all_ssds()
{
	readarray -t all_ssds <<< $(/opt/xo_dc/ssds/ssds -q -l)

	ns="${#all_ssds[@]}"

	for (( i=0; i<$ns; i++ )); do
		this_ssd="${all_ssds[$i]}"
		printf "STARTED Running for ssd: %s\n" "$this_ssd" 2>&1 | tee -a /var/log/xocean_data_centre/bnw_upload.log
		upload_ssd "${this_ssd}"
		printf "FINISHED running for ssd: %s\n" "$this_ssd" 2>&1 | tee -a /var/log/xocean_data_centre/bnw_upload.log
	done
}


upload_all_ssds
exit 0
# Create pid file

if [[ -f "$pid_file" ]]; then
	printf "Process already running.\nExiting...\n"
	exit 0
fi

echo $$ > $pid_file

rm $pid_file
exit 0

count=0
for (( i=0; i<=20; i++ )); do
	printf "Running %s\n" "$0" | /usr/bin/ts >> /tmp/hi.txt
	count=$(($count + 1 ))
	sleep 1800
	upload_all_ssds
done
