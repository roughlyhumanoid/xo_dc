#!/bin/bash
source /etc/xocean/dc.env
source /opt/xo_usv/bash/gen_utils.sh
user_delay=5
ssd_base="$ssd_root"

ssd=$1
force=$2
# sdir=/opt/xo_dc/ssds

function ssd_sum()
{
	while read line; do 
		echo $line	
		mdir=$(echo $line | awk '{print $2}')
		local_count=$(echo "${line}" | awk '{print $7}')
		s3_count=$(echo "${line}" | awk '{print $11}')
		diff_count=$(expr $local_count - $s3_count)
	
		# printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"
		printf "%-10s Local: %-20s S3: %-20s Diff: %10s\n" "Count" "$local_count" "$s3_count" "$diff_count"

		local_size=$(echo "${line}" | awk '{print $8}')
		s3_size=$(echo "${line}" | awk '{print $12}')
		diff_size=$(expr $local_size - $s3_size)
		printf "%-10s Local: %-20s S3: %-20s Diff: %10s\n" "Size" "$local_size" "$s3_size" "$diff_size"

		if [[ "$diff_count" -eq 0 ]] && [[ "$diff_size" -eq 0 ]]; then
			del_dir="/mnt/usb_drives/ssd_${ssd}/${mdir}"
			printf "Run this command if you are sure...\n"
			printf "\nsudo rm -rf %s\n\n" "$del_dir"

			if [[ "$force" == "force" ]]; then
				# sudo rm -rfI "$del_dir" 

				printf "About to permanently remove the following dir: %s\n" "$del_dir"
				printf "You have %d seconds to abort with CTRL-C\n" "$user_delay"
				dots "$user_delay"
				sudo rm -rf "$del_dir" 
			fi
		fi
	done < "${tmpfil}"
}


# tmpfil=$(mktemp)
tmpfil="/tmp/ssd_${ssd}.tmpfil"
if [[ ! -f "$tmpfil" ]]; then rm "$tmpfil"; fi

"${sdir}/ssds" -s "$ssd" -o  | /usr/bin/tee "${tmpfil}"

ssd_label="ssd_${ssd}"
num_entries=$(cat "${tmpfil}" | grep -v '###' | wc -l)
printf "\t%s,\tFound %d matching directories.\n" "$ssd_label" "$num_entries"
# for line in ("${tmpfil}"); do

if [[ "${num_entries}" -gt 0 ]]; then
	ssd_sum
else
	printf "\t%s, No mission folders to upload.\n" "$ssd_label"
	this_ssd_dir="${ssd_base}/ssd_${ssd}"
	printf "\t%s, Contents of this ssd dir: %s\n" "$ssd_label" "$this_ssd_dir"
	ls -l "$this_ssd_dir" | awk -v "ssd_label=$ssd_label"  '{printf "\t\t%s, %s\n",ssd_label,$0}'
fi
exit 0

local_count=$(cat "${tmpfil}" | awk '{print $7}')
s3_count=$(cat "${tmpfil}" | awk '{print $11}')
diff_count=$(expr $local_count - $s3_count)
printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"

local_size=$(cat "${tmpfil}" | awk '{print $8}')
s3_size=$(cat "${tmpfil}" | awk '{print $12}')
diff_size=$(expr $local_size - $s3_size)
printf "Size: %d (local) - %d (s3) = %d (diff)\n" "$local_size" "$s3_size" "$diff_size"
