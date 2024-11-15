#!/bin/bash
ml=/etc/xocean/ssds/ssd_mount_list.txt
ml_temp=/tmp/ssd_mount_list.tmp


function q_add_ssd {		# Add ssd to end of list
	echo $1 >> "${ml}"
}

function q_remove_ssd {		# Remove ssd from list
	dt=$(date +'%Y-%m-%d-%H%M')
	cp "${ml}" "/tmp/ml.bak.${td}"
	cat "${ml}" | grep -v "$1" > "${ml_temp}"
	cp "${ml_temp}" "${ml}"
}

function q_show_ssds {   	# Show ssd list
	cat "${ml}"
}

function q_check_ssd {		# Check if ssd in list
	cat "${ml}" | grep "$1"
}

function q_insert_ssd {		# Insert ssd entry at position
	ssd=$1
	pos=$2
	nl=$(cat "$ml" | wc -l)
	phead=$(expr "$pos" - 1)
	ptail=$(expr "$nl" - "$pos" + 1)

	head -n "$phead" "$ml" > ${ml_temp}
	echo "$1" >> "${ml_temp}"
	tail -n -"${ptail}" "$ml" >> "${ml_temp}"
	cp "${ml_temp}" "${ml}"
}

function q_reload {		# Reload ssd list from mounted and order by number
	/opt/xo_dc/ssds/ssds -q -l > "${ml}"
}

function q_enum {		# Enumerate
	readarray -t ssd_array <<< $(cat "${ml}")
	na="${#ssd_array[@]}"

	for (( i=0;i<$na;i++ )); do 
		this_ssd="${ssd_array[$i]}"
		printf "%d %s\n" "$i" "$this_ssd"
	done
}

function q_help {		# Print help
	cat "/opt/xo_dc/ssds/ssds_queue.sh" | grep -i function | grep -v grep | sed 's/{//g'
}
