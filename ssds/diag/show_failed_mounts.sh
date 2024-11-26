#!/bin/bash
tf=$(mktemp)
/usr/bin/tail -n 50000 /var/log/xocean_data_centre/automount.log \
	| grep 'Unsupported file system type' -B 3 \
	| grep -i 'Going to mount' \
	| awk '{print $1,$2,$3,$4,$11,$13,$17}' \
	> "$tf"

cat "$tf"
printf "\n\n### ----- Summary ----------"
printf "\n# --- Oldest occurence in scan period.\n"
cat "$tf" | uniq -f 5
printf "\n# --- Newest occurence in scan period.\n"
cat "$tf" | tac | uniq -f 5


# DC, Nov 20 09:20:04,  Going to mount SSD Extreme at device path: /dev/sdd1 to mount point: /mnt/usb_drives/ssd_Extreme
