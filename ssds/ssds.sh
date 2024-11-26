#!/bin/bash

which python | grep '/home/xo-mark' >/dev/null 2>&1; result=$?
# if [[ "${result}" -ne 0 ]]; then printf "Loading python environment.\n"; source /home/xo-mark/venv/bin/activate > /dev/null 2>&1; fi
if [[ "${result}" -ne 0 ]]; then source /home/xo-mark/venv/bin/activate > /dev/null 2>&1; fi

# --- Error stuff --- #
function print_error {
    read line file <<<$(caller)
    echo "CAUGHT ERR: An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" | awk '{printf "CAUGHT ERR: %s",$0}' >&2
}

trap print_error ERR

# --- Load libs --- #
script_dir='/opt/xo_usv/bash'
ssd_dir='/opt/xo_dc/ssds'
sd="${ssd_dir}"
source "${script_dir}/gen_utils.sh"
source "${script_dir}/inv_utils.sh"


# --- Set script variables --- #
summary=false
ne=${#exts[@]}
start_index=0
end_index=$ne

check_sync=1
device_id=-1
device_name=''
force=1
just_local=0

mission=''
no_header=1
one_line=1
print_extra_info=1
print_header_only=1
ssd_command=''

quiet=1
query_device=1
query_ssd=1
reload_data=1
verbose=1

# print help
function print_help()
{
	# clear
        printf "\n### Usage for: %s ###\n" "$0"
	h_string=$(printf "### This is not the help file you are looking for.\tBut it will have to do.\tUsage for: %s ###\n\n" "$0")
	echo $h_string
	echo $h_string | sed 's/[a-zA-Z0-9:._\/]/-/g'
	printf "\n"
	# echo $h_string | sed 's/[.]/-/g'

        help_line_long '-a' 'automount' 'Automounts all ssds.  Runs automatically every 10 mins.' 'Example usage:  ssds -a'
        printf "\n"
        help_line_long '-C' 'Check processing' 'Shows running upload processes' 'Example ssds -C'
	printf "\n"
        help_line_long 'diag1' 'Diagnostic info 1' 'Diagnostic info 1' 'ssds diag1'
	printf "\n"
        help_line_long '-e' 'ssd events' 'Shows ssd mount events.' 'Example usage:  ssds -e'
        printf "\n"
        help_line_long '-f' 'query device' 'Diagnostics only: full ssd details list' 'Example usage:  ssds -f'
        printf "\n"
        help_line_long '-H | history' 'Connection history' 'Show SSD connection history' 'Example usage:  ssds -H'
	printf "\n"
        # help_line '-g' 'Print header only' '' 'Example usage:  ssds -g'
        # printf "\n"
        help_line_long '-j | json' 'Get device jsons' 'Diagnostics only: full ssd details list in json format' '' 'Example usage:  ssds -j'
	printf "\n"
        help_line_long '-l | list' 'list' 'List attached SSDs.' 'Example usage:  ssds -l'
	printf "\n"
        help_line_long 'live' 'Show live uploads' 'Show all live upload processes in realtime using htop.' 'Example usage:  ssds live'
	printf "\n"
        help_line_long '-L' 'log level' 'Set log level to one of the standarsd levels:  DEBUG | INFO | WARNING | ERROR | CRTICALL' 'Example usage:  ssds -l -L INFO'
	printf "\n"
	help_line_long '-M | manage' 'manage' '{TESTING ONLY.  NOT OPERATIONAL). SSD queue management.' 'Example usage:  ssds -m'
	printf "\n"
        help_line_long '-q' 'quiet' 'Just print basic info.' 'Example usage:  ssds -l -q'
	printf "\n"
        help_line_long '-Q' 'query device' 'Querys device by id or device path.  Get ID or path by running ssds -l' 'Example usage:  ssds -Q -d /dev/sdp1'
	printf "\n"
        help_line_long '-r | refresh' 'refresh' 'Displays ssd summary page.' 'Example usage:  ssds refresh'
	printf "\n"
        help_line_long '-s | scan' 'Scan and check syncs' 'Scan and check ssd syncs' 'Example usage:  ssds -s 444'
	printf "\n"
        help_line_long 'showfailed' 'Show falied mounts' 'Show failed mounts' 'Example usage:  ssds showfailed'
	printf "\n"
	help_line_long 'sync_history | SH' 'Check ssd sync history' 'Sync history for particular SSD' 'Example usage:  ssds sync_history -S 223'
	help_line_long '' '' '' 'Example usage:  ssds sync_history -S 223 -M X26'
	help_line_long '' '' '' 'Example usage:  ssds sync_history -S 223 -M 241001'
	printf "\n"
        help_line_long '-v' 'verbose' 'Print more verbose info for a command.' 'Example usage:  ssds -l -v'
	printf "\n"
        help_line_long '-h | help' 'help' 'Print this page' 'Example usage:  ssds -h'
	printf "\n"

	span=60
	s2=20
	printf "\n### Examples ### -----------------------------\n\n"
	printf "%-${span}s%-${s2}s\n" "Check what ssds are attached:" "ssds -l"
	printf "%-${span}s%-${s2}s\n" "Check running sync processes:" "ssds -C"
	printf "%-${span}s%-${s2}s\n" "Check sync status of an ssd:" "ssds -s 499"
	printf "%-${span}s%-${s2}s\n" "Check if an ssd is ready to be cleared:" "ssds -X 499"
	printf "%-${span}s%-${s2}s\n" "View latest hourly report on sync status" "ssds status" 
	printf "%-${span}s%-${s2}s\n" "Check sync history for a particular SSD:" "ssds sync_history -S 499"
	printf "%-${span}s%-${s2}s\n" "Check sync history for a particular mission:" "ssds sync_history -S '223 X26_MISSION_20241001'"
	printf "%-${span}s%-${s2}s\n" "Check sync history for a particular mission:" "ssds sync_history -S 223 -M '20241001'"
	printf "\n### End of Examples ### ----------------------\n\n"
}


function list_mission_dirs {
	ssd=$1
	printf "Listing missions dirs for: %s\n" "$ssd"
	query_path="/mnt/usb_drives/ssd_${ssd}"
	ndirs=$(find "${query_path}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | grep -Ev 'RECY|System Volume' | wc -l)

	if [[ "$ndirs" -gt 0 ]]; then
		tmp_fil=$(mktemp)
		find "${query_path}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | grep -Ev 'RECY|System Volume' > "$tmp_fil"
		readarray -t subdirs <<< $(cat $tmp_fil)

		ns="${#subdirs[@]}"
		if [[ "$ns" -eq 0 ]]; then printf "SSD is empty: %s\n" "$ssd"; break; fi

		if [[ "$one_line" -eq 0 ]]; then
			pref=$(printf "%28s" '')
			# "${ssd_dir}/mdsl/cc_disk_stats.sh" -j | awk -v "pref=$pref" '{printf "%s\t%s\n",pref,$0}' | awk NF
		fi

		for (( i=0; i<$ns; i++ )); do
			subdir="${subdirs[$i]}"
			# pref="ssd_${ssd} ${subdir}"
			printf "SSD: %s\tDir: %s\n" "$ssd" "$subdir"
		done
	else
		printf "%s ### SSD has no dierctories for upload ###\n" "ssd_${ssd}"
	fi
}

# --- read input parameters --- #
# Take usv as initial parameter and shift or accept as -x parameter.  Must be first param.
# ssd_command=$1
arg=$1
# check_usv_param ${usv} usv > /dev/null
# result=$?

if [[ ! "${arg:0:1}" == '-' ]]; then 
	ssd_command=$1
	nargs="${#@}"

	if [[ "$nargs" -gt 0 ]]; then
		shift; 
	fi
fi

ssd_dir=/opt/xo_dc/ssds
source "${ssd_dir}/ssd_mounts.sh"


# while getopts "aCde:gikKlpqrs:St:vx:h" opt; do
while getopts "aAc:Cd:efFHi:jlLM:noP::qQrs:S:uvX:h" opt; do
  case $opt in
    A)
	"${ssd_dir}/scan_all.sh"
	ssd_command='scan_all'
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
	check_process=0
	/opt/xo_dc/ssds/run_put_one.sh
	printf "\n\n"
	sleep 1
	ps -eo user,pid,ppid,stime,etime,command | grep -v ^root | grep 'ssd_' | grep -v grep | sort -k11 | awk -F '/' '{printf "%s %s\n",$4,$0}'
	exit 0
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
    F)
        force=0
      ;;
    g)
        print_header_only=0
      ;;
    i)
        device_id=$OPTARG
      ;;
    H)
	ssd_command='ssd_hist'
      ;;
    j)
	ssd_command='lsblk'
      ;;
    k)
        echo "little k"; exit 0
      ;;
    l)
        ssd_command='list'
      ;;
    L)
        log_level=$OPTARG
      ;;
    m)
	query_ssd=0
      ;;
    M)
	mission=$OPTARG
      ;;
    n)
        ssd_command='manage_ssds'
	mission=$OPTARG
      ;;
    o)
	one_line=0
      ;;
    p)
        ssd_command='put_all'
      ;;
    P)
        ssd_command='put_one_mission'
	ssd=$OPTARG
	mission=$OPTARG
      ;;
    q)
        quiet=0
      ;;
    Q)
        query_device=0
      ;;
    r)
        ssd_command='refresh'
      ;;
    s)
	query_ssd=0
        quiet=0
	check_sync=0
	ssd=$OPTARG
        ssd_command='scan_one'
      ;;
    S)
	ssd=$OPTARG
      ;; 
    u)
        just_local=0
      ;;
    v)
        verbose=0
      ;;
    x)
        usv=$OPTARG
      ;;
    X)
        ssd_command='clear_ssd'
	ssd=$OPTARG
      ;;
    h)
	print_help
        exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      print_help
      echo "Invalid option: -$OPTARG"
      printf "You entered %s %s\n" "$0" "$*"
      exit
      ;;
  esac
done

case "$ssd_command" in
  clear_ssd | clear)
	if [[ "$force" -eq 0 ]]; then
		# printf "Not force deleting despite the fact you want me to.\n"
    		# "${sd}/clear_ssd" "$ssd"
    		"${sd}/clear_ssd" "$ssd" force
	else
    		"${sd}/clear_ssd" "$ssd"
	fi
    	exit $?
    ;;

  diag1)
	"${sd}/diag/diag1.sh"
	exit 0
    ;;

  help)
	printf "Command help,  ssds -c 'clear_ssd | help | scan_one | scan-all | lsblk | list | stat1 | stat1_print\n"
	# print_help
	exit 0
    ;;

  kill_upload)
	"${sd}/kill_ssd_upload" "$ssd"
    ;;


  lsblk | json)
	lsblk -aOJ
	exit 0
    ;;
  list)
	if [[ "${quiet}" -eq 0 ]]; then 
		tf=$(mktemp)
		get_ssd_mounts > $tf
		cat $tf | awk '{print $2}'
	elif [[ "${verbose}" -eq 0 ]]; then
		get_ssd_mounts
	else
		tf=$(mktemp)
		get_ssd_mounts > $tf
		cat $tf | awk '{print $2}'
	fi
	exit 0
    ;;

  list_mission_dirs)
	ssd=$1
	list_mission_dirs "$ssd"
	exit 0
    ;;

  live)
	/opt/xo_dc/ssds/htop_sync.sh
	exit 0
    ;;

  manage_ssds)
	source "${sd}/ssds_queue.sh"
	q_help
	exit 0
    ;;

  put_all | upload_all)
	printf "Running ssd by ssd sync staring with lowest ssd num.\n"
	printf "Running run_put_one.sh go\n"
	/opt/xo_dc/ssds/run_put_one.sh go
	exit 0
    ;;
  put_one_mission | upload)
	printf "Going to try to upload data from ssd: %s, missiono: %s\n" "$ssd" "$mission"
	exit 0
	/opt/xo_dc/ssds/put_one.sh "${ssd}" -m "${mission}" >> "/var/log/xocean_data_centre/put_one_${ssd}_${mission}.log" 2>&1 &
	/opt/xo_dc/ssds/ssds -C
	exit 0
    ;;

  refresh | reload | summary)
	printf "### --- Datasync agent status-------------- ###\n"
	datasync -c
	printf "\n"
	printf "### --- Mounted SSDS ---------------------- ###\n"
	/opt/xo_dc/ssds/ssds -l | awk '{printf "\t%s\n",$0}'
	printf "### --------------------------------------- ###\n\n"
	printf "\n"

	# echo won
	printf "### --- SSDS Upload status ---------------- ###\n"
	/opt/xo_dc/ssds/ssds -c stat1_print
        printf "\n\t\t\t\t### NOTE - THIS SUMMARY MAY BE UP TO 1 HOUR OLD! ###\n"
	printf "### --------------------------------------- ###\n\n"
	# echo too
	printf "### --- Active upload processe ------------ ###\n"
	/opt/xo_dc/ssds/ssds -C
	printf "### --------------------------------------- ###\n"
	ls -l /mnt/usb_drives/*/X*
        # printf "### NOTE - This summary may be up to 1 hour old! ###\n"
	# echo tree
	# xsync nc
	# echo fore
	exit 0
    ;;

  scan_one | scan)
	query_ssd=0
    ;;

  scan_all | scanall)
	"${sd}/scan_all" 
	exit 0
    ;;

  ssd_hist | history)
	"${sd}/ssd_history.sh"
	exit 0
    ;;

  showfailed)
	"${sd}/show_failed" 
	exit 0
    ;;

  stat1)
	"${sd}/stat1.sh"
	exit 0
    ;;

  stat1_print | stats | status)
	"${sd}/stat1.sh" "print"
	exit 0
    ;;

  sync_history | SH)
	printf "Running: %s\n" "$ssd_command"
 	cat /var/log/xocean_data_centre/summary_report_01_*.log | grep "${ssd} " | grep "${mission}"
	exit 0
    ;;

  *)
    # echo "no command"
    ;;
esac

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
