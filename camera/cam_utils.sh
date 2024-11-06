#!/bin/bash
script_base=/opt/xo_dc
source "${script_base}/ssds/ssd_mounts.sh"
# dest_bucket='s3://xocean-production-diagnostic-data-eu-west-2'
# dest_base="${dest_bucket}/direct_upload"


function check_already_running()
{
	this_ssd=$1
	this_run_pid=$$
	printf "Checking if job already running for this ssd: %s.\n" "$this_ssd"
	# printf "This run pid:%s\n" "$this_run_pid"
	# ps -ef | grep -i c2.sh | grep -v 'grep' | grep $this_ssd > /dev/null
	# ps -C c2.sh,run_cam.sh -o pid,command | grep 'c2.sh'
	ps -eo pid,command | grep -v $this_run_pid | grep -i c2.sh | grep -v 'grep' | grep $this_ssd > /dev/null
	result=$?
	# printf "Result: %d\n" "$result"
	return $result
}

function ex1()
{
	check_already_running $ssd_num
	result=$?
	if [[ "${result}" -eq 0 ]]; then
		echo oubliex
	fi
}

function get_include_string()
{
	date_key='2024-02-27'
	include_string='USV*TERM1*TERM2*'
	include_string=$(echo $include_string | sed "s/USV/X-18/g")
	include_string=$(echo $include_string | sed "s/TERM1/Ahead/g")
	include_string=$(echo $include_string | sed "s/TERM2/${date_key}/g")
	echo $include_string
}
