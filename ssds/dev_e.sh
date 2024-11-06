#!/bin/bash
ssd=$1
cat /var/log/xocean_data_centre/automount.log \
	| grep $ssd \
	| grep -E 'is not mounted|Attempting to mount|Creating mount|Going to mount'
