#!/bin/bash
ssd=$1
ssd_label="ssd_${ssd}"
grep_string="${ssd_label}|put_one.sh ${ssd}"

function get_ssd_procs {
	ps -ef | grep -iE "${grep_string}" | grep -v 'grep' 
	nprocs=$(ps -ef | grep -iE "$grep_string" | grep -v 'grep'  | wc -l)
	printf "Found %d procs for %s.\n" "$nprocs" "${ssd_label}"
}	

get_ssd_procs

if [[ "$nprocs" -ge 1 ]]; then
	m_pid=$(ps -ef | grep -iE "$grep_string" | grep -v 'grep' | awk '{print $2}')
	printf "About to kill: %s\n" "$m_pid"
	sudo kill $m_pid

	get_ssd_procs
fi

