#!/bin/bash
source /opt/xo_dc/ssds/ssd_mounts.sh
re_use_age=300
file_age=100000
mission=''

# --- Error stuff --- #
function print_error {
    read line file <<<$(caller)
    echo "CAUGHT ERR: An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" | awk '{printf "CAUGHT ERR: %s",$0}' >&2

    # if [[ -f "$tmp_fil" ]]; then rm "$tmp_fli"; fi
}

trap print_error ERR


# --- Load libs --- #
script_dir=/opt/xo_usv/bash
ssd_dir=/opt/xo_dc/ssds
tmp_fil=''
mode='standard'

source "${script_dir}/gen_utils.sh"
source "${script_dir}/inv_utils.sh"
source "${ssd_dir}/ssd_mounts.sh"


# --- Set script variables --- #
ssd_command=$1
quiet=1

# print help
function print_help()
{
	# clear
        printf "\n### Usage for: %s ###\n" "$0"
        printf "### This is not the help file you are looking for.\tBut it will have to do.\nUsage for: %s ###\n" "$0"

        printf "      -------\t\t   -----------\n"
        help_line '-c' 'Some command' 'Some command' "Example ${0} -c do-thing"
	printf "\n"
        help_line '-L' 'log level' 'Set log level to one of the standarsd levels:  DEBUG | INFO | WARNING | ERROR | CRTICALL' "Example usage:  ${0} -l -L INFO"
	printf "\n"
        help_line '-q' 'quiet' 'Just print basic info.  Use with -l.' "Example usage:  ${0} -q"
	printf "\n"
        help_line '-s' 'Scan and check syncs' 'Scan and check ssd syncs' "Example usage:  ${0} -s 444"
	printf "\n"
        help_line '-h' 'help' 'Print this page' "Example usage:  ${0} -h"
	printf "\n"
	printf "\n"
}


# --- read input parameters --- #
# Take ssd_command as initial parameter and shift or accept instead of -c parameter.  Must be first param.  Note, subsequent -c param will override this.
# script.sh 'command-A' -c 'command-B'   #  script will run with command-B
arg=$1
if [[ "${#arg}" -eq 3 ]]; then
        ssd=$arg
        shift
fi


show_count=1
show_size=1

while getopts "cCL:m:qs:Stx:h" opt; do
  case $opt in
    c)
	ssd_command=$OPTARG
      ;;
    C)
	show_count=0
      ;;
    C)
	show_size=0
      ;;
    L)
        log_level=$OPTARG
      ;;
    m)
        mission=$OPTARG
      ;;
    q)
        quiet=0
      ;;
    s)
        ssd=$OPTARG
      ;;
    S)
        show_size=0
      ;;
    t)
        mode=reuse
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
	# print_help
        exit 0
fi

# print_help

# tmp_fil=$(mktemp)
tmp_fil="/tmp/check_clear_ssd_${ssd}.tmp"
# echo "$tmp_fil"

if [[ -f "$tmp_fil" ]]; then
	file_date_epoch=$(stat --format='%Y' "${tmp_fil}")
	now_epoch=$(date +'%s')

	file_age=$(expr "$now_epoch" - "$file_date_epoch")
	# echo $file_age
fi

if [[ "$file_age" -gt 300 ]]; then 
	"${ssd_dir}/clear_ssd.sh" "$ssd" -q -o > "${tmp_fil}"
fi

# cat "$tmp_fil"

while read line; do
	if [[ "$show_count" -eq 0 ]]; then
		echo $line | grep -i 'size' | grep "$mission" | awk '{print $10}'
	elif [[ "$show_size" -eq 0 ]]; then 
		echo $line | grep -i 'size' | grep "$mission" | awk '{print $11}'
	fi
done < "${tmp_fil}"
exit 0
	


readarray -t localdat <<< $(cat "${tmp_fil}" | grep -i 'size' | awk '{print $6}')
readarray -t s3dat <<< $(cat "${tmp_fil}" | grep -i 'size' | awk '{print $8}')

nlines="${#localdat}"
echo "$nlines"

for (( i=0; i<"$nlines"; i++ )); do 
	echo "$localdat[$i]"
	echo "$s3dat[$i]"
done
