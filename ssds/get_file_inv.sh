#!/bin/bash
ssd=$1

base_dir=/mnt/usb_drives
ssd_dir="${base_dir}/ssd_${ssd}"
td=$(date +'%Y-%m-%d_%H%M')
inv_file="/var/log/xocean_data_centre/inventories/ssd_${ssd}_${td}.file.list"
printf "Writing inventory file to: %s\n" "$inv_file"

total_files=$(/usr/bin/find $ssd_dir -type f | wc -l)
printf "Total files from find is: %d\n" "$total_files"

printf "Running inventory...\n"
/usr/bin/find "$ssd_dir" -type f -exec stat --terse {} >> "$inv_file" \; 
nlines=$(cat "$inv_file" | wc -l)
echo $nlines
printf "Done.  Found %d file.\n" "$nlines"



