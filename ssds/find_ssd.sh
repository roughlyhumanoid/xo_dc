#!/bin/bash
ssd=$1
ssd_label="ssd_${ssd}"
cat /var/log/xocean_data_centre/automount*.log | grep -i "$ssd_label" | tail -n 10

