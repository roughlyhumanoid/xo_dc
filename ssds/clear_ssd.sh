#!/bin/bash
# Source
source /etc/xocean/dc.env
source /opt/xo_usv/bash/gen_utils.sh
source /opt/xo_dc/ssds/ssd_mounts.sh

# Default params
user_delay=5
ssd_base="$ssd_root"
one_line=0
quiet=1
just_header=1

# sdir=/opt/xo_dc/ssds
this_host=$(hostname)
s0=8; s1=25; s2=10; s3=12; s4=20; s5=20; s6=20

function just_header()
{
	if [[ "${1}" == "size" ]]; then
		# printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"
		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s SSD: %-20s S3: %-${s5}s Remaining: %-${s6}s  %5spercent\n" \
			"SSD     " "USV_MISSION DIR    " "DC Server" \
			"Size-check" \
			"SSD bytes" "S3 bytes" "Size ( SSD - S3 )  " "Upload status" \
			| sed 's/percent/%/g'
	else
		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s SSD: %-20s S3: %-${s5}s Remaining: %-${s6}s  %5spercent\n" \
			"SSD     " "USV_MISSION DIR    " "DC Server" \
			"Count-check" \
			"$local_count" "$s3_count" "$diff_count" "$count_s3_div_local" \
			| sed 's/percent/%/g'
	fi
}

function is_syncing()
{
	this_ssd=$1
	ps -ef  | grep -i "ssd_${this_ssd}" | grep -Ev 'grep|/mount.ntfs-3g' > /dev/null 2>&1
	result=$?

	return $result
}

function ssd_sum()
{
	this_ssd=$1

	while read line; do 
		if [[ "$quiet" -ne 0 ]]; then echo $line; fi
		ssd_label="ssd_${this_ssd}"
		is_syncing "$this_ssd"
		is_syncing_result=$?

		if [[ "$is_syncing_result" -eq 0 ]]; then 
			sync_string='Syncing'
		else
			sync_string='...'
		fi

		mdir=$(echo $line | awk '{print $2}')

		local_count=$(echo "${line}" | awk '{print $7}')
		s3_count=$(echo "${line}" | awk '{print $11}')
		diff_count=$(expr $local_count - $s3_count)
		# count_s3_div_local=$(expr "$s3_count" / "$local_count")

		if [[ "$local_count" -eq 0 ]]; then
			count_s3_div_local='NA'
		else
			count_s3_div_local=$(( 100 * "$s3_count" / "$local_count"))
		fi
	
		# printf "Count: %d (local) - %d (s3) = %d (diff)\n" "$local_count" "$s3_count" "$diff_count"
		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s SSD: %-20s S3: %-${s5}s Remaining: %-${s6}s  %5spercent %s\n" \
			"$ssd_label" "$mdir" "$this_host" "Count-check" \
			"$local_count" "$s3_count" "$diff_count" "$count_s3_div_local" "${sync_string}"\
			| sed 's/percent/%/g'
		
		local_size=$(echo "${line}" | awk '{print $8}')
		s3_size=$(echo "${line}" | awk '{print $12}')
		diff_size=$(expr $local_size - $s3_size)

		if [[ "$local_size" -eq 0 ]]; then
			size_s3_div_local='NA'
		else
			size_s3_div_local=$(( 100 * "$s3_size" / "$local_size"))
			local_size_GB=$(($local_size / 1024 / 1024 / 1024 ))
		fi

		if [[ "$s3_size" -ne 0 ]]; then
			s3_size_GB=$(($s3_size / 1024 / 1024 / 1024 ))
		else
			s3_size_GB=0;
		fi

		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s SSD: %-20s S3: %-${s5}s  Remaining: %-${s6}s  %5spercent %s \t(SSD: %s GB,  S3: %s GB)\n" \
			"$ssd_label" "$mdir" "$this_host" "Size-check" \
			"$local_size" "$s3_size" "$diff_size" "$size_s3_div_local" "${sync_string}" "$local_size_GB" "$s3_size_GB" \
			| sed 's/percent/%/g'

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
while getopts "FHoqs:h" opt; do
  case $opt in
    F)
        force=0
      ;;
    H)
        just_header=0
	just_header size
	exit 0
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

check_ssd_num "$ssd"
result=$?
if [[ "$result" -ne 0 ]]; then
	printf "Invalid SSD number: %s\n.Exiting\n" "$ssd"
	exit 1
fi

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
		"${sdir}/ssds" -s "$ssd" -o | awk NF > "${tmpfil}"
	else
		"${sdir}/ssds" -s "$ssd" -o  | awk NF | /usr/bin/tee "${tmpfil}"
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
