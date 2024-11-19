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
        ssd_command=$arg
        shift
fi




while getopts "cL:qx:h" opt; do
  case $opt in
    c)
	ssd_command=$OPTARG
      ;;
    L)
        log_level=$OPTARG
      ;;
    q)
        quiet=0
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



function gen_reports {
	"${ssd_dir}/ssds" -c stat1 >> /var/log/xocean_data_centre/stat1.log 2>&1
}

function upload_reports {
	log_dir='/var/log/xocean_data_centre'
	this_dest='S3://xocean-production-transition/DataCentre/DC1/reports/'

	aws s3 sync \
		--profile dc_auto_camera \
		"${log_dir}" "${this_dest}" \
		--dryrun 
		# --exclude "*" \
		# --include "summary_report_01*" \
}

upload_reports

