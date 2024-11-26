#!/bin/bash
# time_limit=7200
process_key=$1
time_limit=$2
force=$3
this_user=$(id -un)
min_seconds=1800
list_only=1
ssd_dir=/opt/xo_dc/ssds
source "${ssd_dir}/ssd_mounts.sh"

function print_help()
{
	printf "%s [PROCESS_KEY] [TIME_LIMIT_SECONDS]\n" "$0"
}


function print_old_procs()
{
	proc_name=$1
	this_time_limit=$2

	printf "\nSummary only for key: %s with time limit %d seconds\n\n" "$proc_name" "$this_time_limit"
	ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "ELAPSED" | grep -v 'grep'
	ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "$proc_name" | grep -v grep | awk "{if(\$3>${this_time_limit}) print \$0}" 
	np=$(ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "$proc_name" | grep -v grep | awk "{if(\$3>${this_time_limit}) print \$0}" | wc -l)
	# echo $np
}



function get_num_procs()
{
	proc_name=$1
	this_time_limit=$2

	# printf "\nSummary only for key: %s with time limit %d seconds\n\n" "$proc_name" "$this_time_limit"
	# ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "ELAPSED" | grep -v 'grep'
	#ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "$proc_name" | grep -v grep | awk "{if(\$3>${this_time_limit}) print \$0}" 
	np=$(ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "$proc_name" | grep -v grep | awk "{if(\$3>${this_time_limit}) print \$0}" | wc -l)
	echo $np
}


function kill_old_procs()
{
	proc_name=$1
	this_time_limit=$2
	ps -e -o pid,user,etimes,stime,etime,cpu,command | grep "$proc_name" | grep -v 'grep' | awk "{if(\$3>${this_time_limit}) print \$0}" | awk '{print $1}' | xargs kill
}

function no_yes_proceed()
{
	read -p "Do you want to proceed? (yes/no/summary) " yns

	case $yns in
		y|yes ) 
			echo ok, we will proceed
			kill_old_procs ${process_key} ${time_limit}
			exit 0
			;;
		n|no ) 
			echo exiting...;
			exit
			;;
		s|summary ) 
			print_old_procs "${process_key}" "${time_limit}"
			echo exiting...;
			exit 0
			;;
		* ) 
			echo Doing nothing.  Exiting...
			exit 1
			;;
	esac
}

function print_params {
	printf "\n# Parameter summary --- #\n"
	printf "Process key: %s\n" "${process_key}"
	printf "Time limit set to: %d\n" "$time_limit"
	printf "Min time limit set to: %d\n" "$min_seconds"
	if [[ "$force" == "force" ]]; then
		printf "Force enabled\n"
	fi
}

nargs="${#@}"
arg=$1
# check_usv_param ${usv} usv > /dev/null
# result=$?

if [[ "$nargs" -gt 0 ]] && [[ "${#arg}" -gt 3 ]] && [[ ! "${arg:0:1}" == '-' ]]; then
        # echo "$*"
        process_key=$1
	printf "Process key: %s\n" "${process_key}"
	shift
        nargs="${#@}"
	arg=$1
        # echo "$*"

	if [[ "${#arg}" -gt 3 ]] && [[ ! "${arg:0:1}" == '-' ]]; then
		time_limit=$1
		printf "Time limit set to: %d\n" "$time_limit"
		shift
        	# echo "$*"
        	nargs="${#@}"
		arg=$1
	
		if [[ "${#arg}" -gt 3 ]] && [[ ! "${arg:0:1}" == '-' ]]; then
			force=$1
			printf "Force enabled\n"
			shift
        		nargs="${#@}"
     			# echo "$*"
		fi
	fi
        # if [[ "$nargs" -gt 0 ]]; then
         #       shift;
        #fi
fi



# echo "$*"
# while getopts "aCde:gikKlpqrs:St:vx:h" opt; do
while getopts "flm:p:t:h" opt; do
  case $opt in
    f)
        force='force'
      ;;
    l)
        list_only=0
      ;;
    m)
        min_seconds=$OPTARG
      ;;
    p)
        process_key=$OPTARG
      ;;
    t)
        time_limit=$OPTARG
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


print_params

if [[ "${#process_key}" -lt 5 ]]; then printf "Process key too short: %s\n" "${process_key}"; print_help; exit 1; fi

if [[ "${list_only}" -eq 0 ]]; then 
	print_old_procs ${process_key} ${time_limit}
	exit 0
fi

if [[ "${time_limit}" -lt "$min_seconds" ]]; then 
	echo $force
	echo gothere

	if [[ ! "$force" == "force" ]]; then
		printf "Time limit too short: %s\n" "${time_limit}"; 
		print_help; 
		exit 1; 
	fi
fi


print_old_procs ${process_key} ${time_limit}
nprocs=$(get_num_procs ${process_key} ${time_limit})
printf "Found %d procs\n" "$nprocs"

if [[ "$nprocs" -gt 0 ]]; then
	no_yes_proceed
fi




exit 0
ps -e -o pid,etimes,stime,etime,cpu,command | grep "$target_proc" | awk "{if(\$2>${time_limit}) print \$0}" 
# ps -e -o pid,etimes,stime,etime,cpu,command | grep '\-c stats' | awk "{if(\$2>${time_limit}) print \$0}" | awk '{print $1}' | xargs kill
ps -e -o pid,etimes,stime,etime,cpu,command | grep "$target_proc" | awk "{if(\$2>${time_limit}) print \$0}" | awk '{print $1}' | xargs kill

no_yes_proceed
# exit 0
# ps -e -o pid,etimes,command | awk '$2 > 7200'
