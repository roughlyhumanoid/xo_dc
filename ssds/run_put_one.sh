#!/bin/bash
max_procs=4
ssd=$1
tail_this=$2
sdir=/opt/xo_dc/ssds


if [[ "${#ssd}" -le 2 ]]; then
	printf "Usage: %s 499\n" "$0"
	ps -ef | grep -i ./put_one.sh | grep -v grep
	nprocs=$(ps -ef | grep -i ./put_one.sh | grep -v grep | wc -l)
	printf "%d instances running\n" "$nprocs"

	if [[ "${ssd}" == "go" ]]; then
	      	if [[ "${nprocs}" -ge "$max_procs" ]]; then
			printf "Too many uploads running ( %d running ).  Wait till current batch finish or manually override.\n" "$nprocs"
			exit 0
		fi

		printf "Running in auto mode.\n"
		tf=$(mktemp)
		/opt/xo_dc/ssds/ssds -q -l > "$tf"

		readarray -t ssds <<< $(cat "$tf")
		ns="${#ssds[@]}"

		for (( i=o; i<$ns; i++ )); do
			nprocs=$(ps -ef | grep -i ./put_one.sh | grep -v grep | wc -l)

	      		if [[ "${nprocs}" -gt "$max_procs" ]]; then
				printf "Too many uploads running ( %d running ).  Wait till current batch finish or manually override.\n" "$nprocs"
				exit 0
			fi

		        this_ssd="${ssds[$i]}"
        		printf "Running for: %s\n" "$this_ssd" 

			ps -ef | grep -i ./put_one.sh | grep -v grep | grep "put_one.sh ${this_ssd}"
			result=$?

			if [[ "$result" -eq 0 ]]; then 
				printf "Already running for this ssd: %s\n" "$this_ssd"
				continue
			else
				printf "Not lready running for this ssd: %s\nGoing to run now...\n\n" "$this_ssd"
				printf "%s %s\n" "${sdir}/run_put_one.sh" "$this_ssd"
				"${sdir}/run_put_one.sh" "$this_ssd"
			fi
					
			sleep 60
			printf "%d instances running\n" "$nprocs"
			ps -ef | grep -i ./put_one.sh | grep -v grep
		done

		rm "$tf"
	fi

	exit 0
fi

log_fn="/var/log/xocean_data_centre/put_one_${ssd}.log"
/opt/xo_dc/ssds/put_one.sh "$ssd" >> "$log_fn" 2>&1 &
run_pid=$!

if [[ "$tail_this" == "tail" ]] || [[ "$tail_this" == 't' ]]; then
	/usr/bin/grc /usr/bin/tail -f "$log_fn" --pid="$run_pid"
fi


printf "Finished this run: %s %s\n" "$0" "$*"



