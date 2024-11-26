#!/bin/bash
ssd=$1
mkey=$2
cat /var/log/xocean_data_centre/summary_report_01_2024-11-* | grep "ssd_${ssd}" | grep "${mkey}" | awk '{print $1,$2,$3,$4,$5,$14}' | uniq -f5
