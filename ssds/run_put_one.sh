#!/bin/bash
ssd=$1
log_fn="/var/log/xocean_data_centre/put_one_${ssd}.log"
/opt/xo_dc/ssds/put_one.sh "$ssd" >> "$log_fn" 2>&1 &
run_pid=$!

/usr/bin/grc /usr/bin/tail -f "$log_fn" --pid="$run_pid"
