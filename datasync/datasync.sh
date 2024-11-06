#!/bin/bash
# --- Error stuff --- #
function print_error {
    read line file <<<$(caller)
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}

trap print_error ERR


# --- Load libs --- #
script_dir=/opt/xo_usv/bash
source "${script_dir}/gen_utils.sh"
source "${script_dir}/inv_utils.sh"


# --- Set script variables --- #
ds_dir=/opt/xo_dc/datasync
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


# print help
function print_help()
{
	clear
        printf "\n### Usage for: %s ###\n" "$0"
        printf "### This is not the help file you are looking for.\tBut it will have to do.\nUsage for: %s ###\n" "$0"
        printf "      -------\t\t   -----------\n"
        help_line '-c' 'check' 'check dsagent status.' 'Example usage:  datasync -c'
        printf "\n"
        help_line '-r' 'run' 'starts dsagent.' 'Example usage:  datasync -r'
        printf "\n"
        help_line '-S' 'STOP' 'Stops dsagent.' 'Example usage:  datasync -S'
	printf "\n\n"
}

function dots()
{
	n=$1

	for (( i=0; i<=$n; i++ )); do
		printf ". "
		sleep 1
	done

	printf "\n"
}



while getopts "crSh" opt; do
  case $opt in
    c)
	"${ds_dir}/check_dsagent.sh"
	exit 0
      ;;
    r)
	"${ds_dir}/start_dsagent.sh"
	dots 5
	"${ds_dir}/check_dsagent.sh"
	exit 0
      ;;
    l)
        log_level=$OPTARG
	exit 0
      ;;
    S)
	"${ds_dir}/halt_dsagent.sh"
	dots 15
	"${ds_dir}/check_dsagent.sh"
	exit 0
      ;;
    v)
        verbose=0
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

print_help
