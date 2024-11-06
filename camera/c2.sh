#!/bin/bash
script_base=/opt/xo_dc
#source /home/xo-mark/scripts/ssd_mounts.sh
#source /home/xo-mark/scripts/camera/cam_utils.sh
source "$script_base/ssds/ssd_mounts.sh"
source "$script_base/camera/cam_utils.sh"

source_base='/mnt/usb_drives'
dest_bucket='s3://xocean-production-diagnostic-data-eu-west-2'
dest_base="${dest_bucket}/direct_upload"

dryrun=1
ssd_num='N'
info_only=1
list=1
quiet=1
wait_for_end=1
check_only=1
print_size=1
run_now=1

function print_help()
{
	printf "c2.sh [-l] [-s SSD_NUM] [-d] [-p]\n"
	printf "\n"
	printf "option:\t-l\tlist ssds only\n"
	printf "\t\tExample: run_cam.sh -l\n"
	printf "\n"
	printf "option:\t-s\tssd.\n"
	printf "\t\tExample: run_cam.sh -s 901\n"
	printf "\n"
	printf "option:\t-p\tprint info only.\n"
	printf "\t\tExample: run_cam.sh -s 901 -p\n"
	printf "\n"
	printf "option:\t-S\tWith -p will print size of camera sub dirs\n"
	printf "\t\tExample: run_cam.sh -s 901 -p -S\n"
	printf "\n"
	printf "option:\t-d\tdryrun\n"
	printf "\t\tExample: run_cam.sh -s 901 -d\n"
	printf "\n"
	printf "option:\t-r\trun job for real. Not dry run\n"
	printf "\t\tExample: run_cam.sh -s 901 -r\n"
	printf "\n"
	printf "\n"
	printf "Example - show camera data size for ssd 901:\t\trun_cam.sh -s 901 -p -S\n"
	printf "Example - Dryrun camera data sync for ssd 901:\t\trun_cam.sh -s 901 -d\n"
	printf "Example - Real camera data sync for ssd 901:\t\trun_cam.sh -s 901 -r\n"
	printf "\n"
	printf "\n"
}

while getopts "cdilpqrs:Svwx:h" opt; do
  case $opt in
    c)
        check_only=0
      ;;
    d)
        dryrun=0
      ;;
    i)
        print_extra_info=0
      ;;
    l)
        list=0
      ;;
    p)
        info_only=0
	print_size=0
      ;;
    q)
        quiet=0
      ;;
    r)
        run_now=0
      ;;
    s)
        ssd_num=$OPTARG
      ;;
    S)
        info_only=0
        print_size=0
      ;;

    v)
	# View
	# /opt/xo_dc/camera/show_uploads.sh
	exit 0
      ;;
    w)
        wait_for_end=0
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

if [[ "$list" -eq 0 ]]; then
	get_ssd_mounts
	exit 0
fi

ssd_nl="${#ssd_num}"
# printf "nl: %d\n" "$ssd_nl"
# exit 0

if [[ "${#ssd_num}" -lt 2 ]]; then
	printf "Invalid ssd number: %s\n" "$ssd_num"
fi

function check_ssd_attached()
{
	# if [[ "$(get_ssd_mounts | grep 345)" ]]; then echo hi; else echo boo; fi
	get_ssd_mounts | grep $1 > /dev/null
	result=$?
	return $result
}

# if [[ ! "$(check_ssd_attached ${ssd_num})" ]]; then printf "SSD %s not attached.\n" $ssd_num; exit 1; fi
ssna=$(check_ssd_attached "$ssd_num")
result=$?
if [[ ! "$result" ]]; then printf "SSD %s not attached.\n" $ssd_num; exit 1; fi

check_already_running $ssd_num
result=$?

if [[ "${result}" -ne 0 ]]; then
	printf "Job not already running for this ssd: %s.  Ok to proceed.\n" "$ssd_num"
else
	printf "Job already running for this ssd: %s.\n" "$ssd_num"

	if [[ "$check_only" -eq 0 ]]; then
		this_run_pid=$$
		watch -c "ps -ef | grep -v $this_run_pid | grep -i c2.sh | grep -v 'grep' | grep $this_ssd"
	fi

	printf "Exiting...\n"
	exit 1
fi

ssd_dir="ssd_${ssd_num}"
ssd_path="${source_base}/${ssd_dir}"
# ssd_cam_paths=$(find  "${ssd_path}" -maxdepth 3 -type d -name "Camera" | grep -iv 'RECYCLE')

mapfile -d $'\0' ssd_cam_paths < <(find "${ssd_path}" -maxdepth 3 -type d -name "Camera" -print0) #  | grep -iv 'RECYCLE') 

nc_path="${#ssd_cam_paths[@]}"
printf "Found %s directories on %s with camera data\n" "$nc_path" "$ssd_dir"

for (( i=0; i<$nc_path; i++ )); do
	# printf "Camera set: %d\n" "$i"

	cam_path=$(echo "${ssd_cam_paths[$i]}" |  awk '{$1=$1};1')

	if [[ "$cam_path" = *RECYCLE* ]]; then 
		printf "Path contains RECYCLE.  Skipping...\n"
		continue
	fi
	
	#	echo $cam_path
	source_path="$cam_path"
	printf "Searching ssd camera path: \t%s\n\n" "$source_path"
	printf "Destination\nDest bucket: %s\n" "$dest_bucket"
	printf "Dest path: %s\n\n" "$dest_base"

	if [[ "$info_only" -eq 0 ]]; then
		printf "Just printed task info only.\nSkipping even doing dryrun.\n"; 

		if [[ "$print_size" -eq 0 ]]; then
			printf "Cam path: %s\n" "${cam_path}"
			cd $cam_path
			/usr/bin/du -sh * 
		fi

		continue
	fi

	if [[ -d "$source_path" ]]; then
		printf "Uploading data from: %s\n" "$source_path"
		if [[ "$dryrun" -eq 0 ]]; then
			printf "Dryrun...\n"
			aws s3 --profile dc_auto_camera sync "$source_path" "$dest_base"  --no-progress --output text  --dryrun
		elif [[ "$run_now" -eq 0 ]]; then
			printf "Running for real...\n"
			aws s3 --profile dc_auto_camera sync "$source_path" "$dest_base"  --no-progress --output text 
		else
			# printf "Not sure what you're doing are you?\n"
			print_help
		fi	
	else
		printf "\n\nSource path %s does not exist.  Exiting...\n" "${source_path}"
	fi
done


if [[ "$run_now" -eq 1 ]]; then 
	printf "\n!!! WARNING:  Not syncing.  To sync specify -r.\n"
	printf "\n!!! WARNING:  Not syncing.  To sync specify -r.\n"
fi
