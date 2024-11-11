#!/bin/bash
ssd=$1
/opt/xo_dc/ssds/put_one.sh "$ssd" >> "/var/log/xocean_data_centre/put_one_${ssd}.log" 2>&1 &

