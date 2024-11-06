#!/bin/bash
script_dir=/opt/xo_dc
#source /home/xo-mark/scripts/ssd_mounts.sh
source "${script_dir}/ssds/ssd_mounts.sh"
#c2_path=/home/xo-mark/scripts/camera/c2.sh
c2_path=/opt/xo_dc/camera/c2.sh
quiet=1
ssd_num='not_set'
wait_for_end=1
view_log=1

function print_run_cam_help()
{
	"$c2_path" -h
	print_extra_help
	printf "\nCurrent ssd mounts\n"
	get_ssd_mounts_2
}


function print_extra_help()
{
        printf "option:\t-a\tShow running processes for All SSDs\n"
        printf "\t\tExample: run_cam.sh -a\n"
}


while getopts "acdilLpqs:rSx:h" opt; do
  case $opt in
    a)
	list_procs.sh
	exit 0
      ;;
    d)
        dryrun=0
      ;;
    i)
        print_extra_info=0
      ;;
    l)
        list=0
	get_ssd_mounts_2
	exit 0
      ;;
    L)
	view_log=0
      ;;

    q)
        quiet=0
      ;;
    p)
        info_only=0
      ;;
    s)
        ssd_num=$OPTARG
      ;;
    v)
        # verbose=0
      ;;
    x)
        usv=$OPTARG
      ;;
    h)
        # print_help
	print_run_cam_help
        exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit
      ;;
  esac
done

if [[ "${#@}" -eq 0 ]]; then 
	printf "No args\n"
	print_run_cam_help
	exit 1
fi

# ssd_num=$1
dt=$(date +'%Y-%m-%d')


if [[ "$view_log" -eq 0 ]]; then
	# If just view cam log

	if [[ "$ssd_num" == 'not_set' ]]; then
		printf "SSD num missing.  Please use -L -s [SSD_NUM]\n"
		exit 1
	fi
	cam_file=$(ls -1rt /var/log/xocean_data_centre/camera_uploads*${ssd_num}*.log | tail -n 1)
	tail -n 100 -f $cam_file
	exit 0
fi

if [[ "$ssd_num" == 'not_set' ]]; then
	ssd_num='general'
fi

log_fp="/var/log/xocean_data_centre/camera_uploads_${ssd_num}_${dt}.log"

if [[ "$wait_for_end" -eq 0 ]]; then
	#/home/xo-mark/scripts/camera/c2.sh "$@" | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> "${log_fp}" 2>&1 
	"${script_dir}/camera/c2.sh" "$@" | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> "${log_fp}" 2>&1 
	# xrun_pid=$!
else
	printf "\n\n### Starting new run ###\n\n"
	#/home/xo-mark/scripts/camera/c2.sh "$@" | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> "${log_fp}" 2>&1 &
	"${script_dir}/camera/c2.sh" "$@" | /usr/bin/ts "DC, %b %d %H:%M:%S, " >> "${log_fp}" 2>&1 &
	xrun_pid=$!

	printf "Log written to: %s\n" "$log_fp"
	printf "Running with pid=${xrun_pid}\n\n"

	if [[ "$quiet" -ne 0 ]]; then
		printf "Press CTRL-C to exit log.  Job will proceed in backgroud\n"
		/usr/bin/tail -n 0 -f ${log_fp} --pid=$xrun_pid
	fi
fi


printf "Log written to: %s\n" "$log_fp"
