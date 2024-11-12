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
	# /usr/bin/duc index -x --uncompressed -d ${db} ${target}


	jq_string='.blockdevices[] | select (.subsystems=="block:scsi:usb:pci") | select (.children[0].label | contains("SSD_NUM"))'
	jq_string=$(echo $jq_string | sed "s/SSD_NUM/${this_ssd}/g")
	printf "Jq string: %s\n" "$jq_string"
	json_fn="ssd_${this_ssd}.${td}.json"
	json_fil="/var/log/xocean_data_centre/inventories/${json_fn}"
	s3_fil="s3://xocean-production-raw-dc-eu-west-2/DC1/ssd_${this_ssd}/device_info/${json_fn}"
	/opt/xo_dc/ssds/ssds -j | jq -r "$jq_string" > "${json_fil}"

	printf "Uploading file from: %s to %s\n" "$json_fil" "$s3_fil"
	aws --profile dc_auto_camera s3 cp  "${json_fil}" "${s3_fil}"

done	
