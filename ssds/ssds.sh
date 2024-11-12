#!/bin/bash
# --- Error stuff --- #
function print_error {
    read line file <<<$(caller)
    echo "CAUGHT ERR: An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" | awk '{printf "CAUGHT ERR: %s",$0}' >&2
}

trap print_error ERR


# --- Load libs --- #
script_dir=/opt/xo_usv/bash
ssd_dir=/opt/xo_dc/ssds
source "${script_dir}/gen_utils.sh"
source "${script_dir}/inv_utils.sh"


# --- Set script variables --- #
summary=false
ne=${#exts[@]}
start_index=0
end_index=$ne
verbose=1
reload_data=1
print_header_only=1
no_header=1
print_extra_info=1
ssd_command=$OPTARG
query_device=1
device_id=-1
device_name=''
quiet=1
query_ssd=1
check_sync=1
just_local=0
one_line=1

# print help
function print_help()
{
	clear
        printf "\n### Usage for: %s ###\n" "$0"
        printf "### This is not the help file you are looking for.\tBut it will have to do.\nUsage for: %s ###\n" "$0"

        printf "      -------\t\t   -----------\n"
        help_line '-a' 'automount' 'Automounts all ssds.  Runs automatically every 10 mins.' 'Example usage:  ssds -a'
        printf "\n"
        help_line '-e' 'ssd events' 'Shows ssd mount events.' 'Example usage:  ssds -e'
        printf "\n"
        help_line '-f' 'Diagnostics only: full ssd details list' '' 'Example usage:  ssds -f'
        printf "\n"
        # help_line '-g' 'Print header only' '' 'Example usage:  ssds -g'
        # printf "\n"
        help_line '-j' 'Diagnostics only: full ssd details list in json format' '' 'Example usage:  ssds -j'
	printf "\n"
        help_line '-l' 'list' 'List attached SSDs.' 'Example usage:  ssds -l'
	printf "\n"
        help_line '-L' 'log level' 'Set log level to one of the standarsd levels:  DEBUG | INFO | WARNING | ERROR | CRTICALL' 'Example usage:  ssds -l -L INFO'
	printf "\n"
        help_line '-q' 'quiet' 'Just print basic info.  Use with -l.' 'Example usage:  ssds -q -l'
	printf "\n"
        help_line '-Q' 'query device' 'Querys device by id or device path.  Get ID or path by running ssds -l' 'Example usage:  ssds -Q -d /dev/sdp1'
	printf "\n"
        help_line '-s' 'Scan and check syncs' 'Scan and check ssd syncs' 'Example usage:  ssds -s 444'
	printf "\n"
        help_line '-h' 'help' 'Print this page' 'Example usage:  ssds -h'
	printf "\n"

	printf "\n"
}


# --- read input parameters --- #
# Take usv as initial parameter and shift or accept as -x parameter.  Must be first param.
ssd_command=$1
# check_usv_param ${usv} usv > /dev/null
# result=$?
# if [[ "${result}" -eq 0 ]]; then shift; fi

ssd_dir=/opt/xo_dc/ssds
source "${ssd_dir}/ssd_mounts.sh"


# while getopts "ade:gikKlqrs:St:vx:h" opt; do
while getopts "aACd:efi:jloqQs:uh" opt; do
  case $opt in
    A)
	"${ssd_dir}/scan_all.sh"
	exit 0
      ;;
    a)
	sudo "${ssd_dir}/auto_mount.sh" 'tail'
	exit 0
      ;;
    c)
	ssd_command=$OPTARG
      ;;
    C)
	check_sync=0
      ;;
    d)
	device_name=$OPTARG
      ;;
    e)
    	eval nextopt=\${$OPTIND}
    	# existing or starting with dash?

    	if [[ -n $nextopt && $nextopt != -* ]] ; then
      		OPTIND=$((OPTIND + 1))
		target_ssd=$nextopt
		printf "Target ssd: %s\n" "$target_ssd"
		"${ssd_dir}/ssd_events.sh" | grep -i $target_ssd
		exit 0
    	else
      		level=1
		"${ssd_dir}/ssd_events.sh"
    	fi

	exit 0
      ;;
    f)
	source "${ssd_dir}/ssd_mounts.sh"
	ssd_all
	exit 0
      ;;
    g)
        print_header_only=0
      ;;
    i)
        device_id=$OPTARG
      ;;
    j)
        lsblk -aOJ
	exit 0
      ;;
    k)
        echo "little k"; exit 0
      ;;
    l)
        # log_level=$OPTARG
	if [[ "${quiet}" -eq 0 ]]; then 
		tf=$(mktemp)
		get_ssd_mounts > $tf
		cat $tf | awk '{print $2}'
	else
		get_ssd_mounts
	fi
	exit 0
      ;;
    L)
        log_level=$OPTARG
      ;;
    m)
	query_ssd=0
      ;;
    o)
	one_line=0
      ;;
    q)
        quiet=0
      ;;
    s)
	query_ssd=0
        quiet=0
	check_sync=0
	ssd=$OPTARG
      ;;
    u)
        just_local=0
      ;;
    Q)
        query_device=0
      ;;
    x)
        usv=$OPTARG
      ;;
    h)
	print_help
        exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit
      ;;
  esac
done


if [[ "$query_device" -eq 0 ]]; then
	printf "Querying device.\n"

	if [[ "$device_id" -ne -1 ]]; then
		printf "Using device id: %d\n" "$device_id"
		query_ssd_dev_by_id "$device_id"
	elif [[ ! "$device_name" == '' ]]; then
		printf "Using device name: %s\n" "$device_name"

		if [[ -b "$device_name" ]]; then 
			query_ssd_dev $device_name
		else
			printf "Invalid device name: %s\n" "$device_name"
		fi
	else
		printf "Invalid device name or path!\nSpecify with -i or -d\n"
	fi

	exit 0
fi

if [[ "$query_ssd" -eq 0 ]]; then
	query_path="/mnt/usb_drives/ssd_${ssd}"

	if [[ ! -d "$query_path" ]]; then printf "Directory does not exist: %s\n" "$query_path"; exit 0; fi

	if [[ ! "$quiet" -eq 0 ]]; then
		printf "ssd_%s\tPrinting sub_dirs of: %s\n" "$ssd"  "$query_path"
		ls -l "${query_path}" | grep -Ev 'RECY|System Volume'
	fi

	# ls -1 "${query_path}" | grep -Ev 'RECY|System Volume'

	if [[ "$check_sync" -eq 0 ]]; then
		this_ssd="ssd_${ssd}"
		tmp_fil=$(mktemp)
		# ls -1 "${query_path}" | grep -Ev 'RECY|System Volume' > $tmp_fil
		# echo $query_path
		# ls -1 "${query_path}" 
		# find "${query_path}" -maxdepth 1 -mindepth 1 -type d -exec ls -1 {} \; 
		# | grep -Ev 'RECY|System Volume' > $tmp_fil
		# exit 0	
		ndirs=$(find "${query_path}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | grep -Ev 'RECY|System Volume' | wc -l)

		if [[ "$ndirs" -gt 0 ]]; then
			find "${query_path}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | grep -Ev 'RECY|System Volume' > "$tmp_fil"
			readarray -t subdirs <<< $(cat $tmp_fil)
			ns="${#subdirs[@]}"

			if [[ "$ns" -eq 0 ]]; then printf "SSD is empty: %s\n" "$ssd"; break; fi

			if [[ "$one_line" -eq 0 ]]; then
			# pref="ssd_${ssd} ALL MISSIONS"
				pref=$(printf "%28s" '')
			# "${ssd_dir}/mdsl/cc_disk_stats.sh" -j | awk -v "pref=$pref" '{printf "%s\t%s\n",pref,$0}' | awk NF
			fi

			for (( i=0; i<$ns; i++ )); do
				subdir="${subdirs[$i]}"
				pref="ssd_${ssd} ${subdir}"

				if [[ "${quiet}" -ne 0 ]]; then printf "%s\tChecking: ssd: %s, mission: %s\n" "$pref" "$this_ssd" "$subdir"; fi

				if [[ "$one_line" -eq 0 ]]; then
					"${ssd_dir}/mdsl/cc_disk_stats.sh" -H -o -q -p "${this_ssd}" -d -q -m "$subdir" -D | awk -v "pref=$pref" '{printf "%-35s%s\n",pref,$0}' | awk NF
				else
					"${ssd_dir}/mdsl/cc_disk_stats.sh" -p "${this_ssd}" -d -q -m "$subdir" -D | awk -v "pref=$pref" '{printf "%-35s%s\n",pref,$0}' | awk NF
				fi
			done

			rm $tmp_fil

			if [[ "$one_line" -ne 0 ]]; then
				ls -l "${query_path}" | grep -v total | awk -v "ssd=ssd_${ssd}" '{printf "%s\tALL\t%s\n",ssd,$0}' 
			fi
			# | grep -Ev 'RECY|System Volume' | 
		else
			printf "%s ### SSD has no dierctories for upload ###\n" "ssd_${ssd}"
		fi
	fi
else
	print_help
fi

exit 0
# --- checks --- #
# Check if print header only
if [[ "$print_header_only" -eq 0 ]]; then print_header; exit 0; fi




if [[ "$result" -ne 0 ]]; then 
	printf "Error!\n"
	print_help
       	exit 1; 
fi

printf "umbrish\n"

# If verbose
if [[ "$verbose" -eq 0 ]]; then echo verbose; fi
