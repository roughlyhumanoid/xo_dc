#!/bin/bash
ssd=$1
tmpfil=$(mktemp)
tmpfil="/tmp/ssd_${ssd}.tmpfil"
sdir=/opt/xo_dc/ssds
rm $tmpfil
"${sdir}/ssds" -s "$ssd" -o  | /usr/bin/tee "${tmpfil}"

# for line in ("${tmpfil}"); do
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
		printf "Deleting this dir: %s\n" "$del_dir"
		printf "Run this command if you are sure...\n"
		printf "\nsudo rm -rf %s\n\n" "$del_dir"
	fi
done < "${tmpfil}"
exit 0

local_count=$(cat "${tmpfil}" | awk '{print $7}')
s3_count=$(cat "${tmpfil}" | awk '{print $11}')
diff_count=$(expr $local_count - $s3_count)
printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"

local_size=$(cat "${tmpfil}" | awk '{print $8}')
s3_size=$(cat "${tmpfil}" | awk '{print $12}')
diff_size=$(expr $local_size - $s3_size)
printf "Size: %d (local) - %d (s3) = %d (diff)\n" "$local_size" "$s3_size" "$diff_size"
