#!/bin/bash
# Source
source /etc/xocean/dc.env
source /opt/xo_usv/bash/gen_utils.sh

# Default params
user_delay=5
ssd_base="$ssd_root"
one_line=0
quiet=1

# sdir=/opt/xo_dc/ssds
this_host=$(hostname)

function ssd_sum()
{
	this_ssd=$1

	while read line; do 
		if [[ "$quiet" -ne 0 ]]; then echo $line; fi
		ssd_label="ssd_${this_ssd}"

		mdir=$(echo $line | awk '{print $2}')

		local_count=$(echo "${line}" | awk '{print $7}')
		s3_count=$(echo "${line}" | awk '{print $11}')
		diff_count=$(expr $local_count - $s3_count)
	
		# printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"
		s0=8; s1=25; s2=10; s3=10
		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s Local: %-20s S3: %-20s Diff: %10s\n" \
			"$ssd_label" "$mdir" "$this_host" "Count" \
			"$local_count" "$s3_count" "$diff_count"
		
		local_size=$(echo "${line}" | awk '{print $8}')
		s3_size=$(echo "${line}" | awk '{print $12}')
		diff_size=$(expr $local_size - $s3_size)
		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s Local: %-20s S3: %-20s Diff: %10s\n" \
			"$ssd_label" "$mdir" "$this_host" "Size" \
			"$local_size" "$s3_size" "$diff_size"

		if [[ "$diff_count" -eq 0 ]] && [[ "$diff_size" -eq 0 ]]; then
			del_dir="/mnt/usb_drives/${ssd_label}/${mdir}"
			
			if [[ "${quiet}" -ne 0 ]]; then
				printf "Run this command if you are sure...\n"
				printf "\nsudo rm -rf %s\n\n" "$del_dir"
			fi

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

function log {
	if [[ "${quiet}" -ne 0 ]]; then
		printf "%s\n" "$*"
	fi
}

function print_help {
	printf "%s SSD_NUM [force] [-F] [-o] [-q] [-s] [-h]\n"
}


arg=$1
force=$2

if [[ "${#arg}" -eq 3 ]] && [[ "$(is_a_number $arg)" -eq 0 ]]; then
        ssd=$arg
	# log "Setting ssd to ${ssd}"
        shift

	arg=$1

	if [[ "${arg}" == "force" ]]; then
		force='force'
		# log "Setting delete to force."
		shift
	fi
fi


# while getopts "ade:gikKlqrs:St:vx:h" opt; do
while getopts "Foqs:h" opt; do
  case $opt in
    F)
        force=0
      ;;
    o)
        one_line=0
      ;;
    q)
        quiet=0
      ;;
    s)
        ssd=$OPTARG
      ;;
    h)
        print_help
        exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      print_help
      exit
      ;;
  esac
done

# Check ssd param

ssd_label="ssd_${ssd}"
tmpfil="/tmp/ssd_${ssd}.tmpfil"


if [[ "${#ssd}" -ne 3 ]] || [[ "$(is_a_number $ssd)" -ne 0 ]]; then
	printf "Bad ssd number: %s\n" "$ssd"
	exit 1
fi

function get_summary_data {
	# tmpfil=$(mktemp)

	if [[ -f "$tmpfil" ]]; then rm "$tmpfil"; fi

	if [[ "$quiet" -eq 0 ]]; then
		"${sdir}/ssds" -s "$ssd" -o > "${tmpfil}"
	else
		"${sdir}/ssds" -s "$ssd" -o  | /usr/bin/tee "${tmpfil}"
	fi
}

get_summary_data

num_entries=$(cat "${tmpfil}" | grep -v '###' | wc -l)

if [[ "${quiet}" -ne 0 ]]; then
	printf "\t%s,\tFound %d matching directories.\n" "$ssd_label" "$num_entries"
fi
# for line in ("${tmpfil}"); do

if [[ "${num_entries}" -gt 0 ]]; then
	ssd_sum "$ssd"
else
	printf "\t%s, No mission folders to upload.\n" "$ssd_label"
	this_ssd_dir="${ssd_base}/ssd_${ssd}"

	if [[ "${quiet}" -ne 0 ]]; then
		printf "\t%s, Contents of this ssd dir: %s\n" "$ssd_label" "$this_ssd_dir"
		ls -l "$this_ssd_dir" | awk -v "ssd_label=$ssd_label"  '{printf "\t\t%s, %s\n",ssd_label,$0}'
	fi
fi
exit 









local_count=$(cat "${tmpfil}" | awk '{print $7}')
s3_count=$(cat "${tmpfil}" | awk '{print $11}')
diff_count=$(expr $local_count - $s3_count)
printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"

local_size=$(cat "${tmpfil}" | awk '{print $8}')
s3_size=$(cat "${tmpfil}" | awk '{print $12}')
diff_size=$(expr $local_size - $s3_size)
printf "Size: %d (local) - %d (s3) = %d (diff)\n" "$local_size" "$s3_size" "$diff_size"
