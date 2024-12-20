#!/bin/bash
td=$(date +'%Y-%m-%d_%H%M')
this_host=$(hostname)
info_dir="/var/log/xocean_data_centre/inventories"
ssd_info_json="${info_dir}/ssd_info_${this_host}_${td}.json"
ssd_info_csv="${info_dir}/ssd_info_${this_host}_${td}.csv"
ssd_info_tsv="${info_dir}/ssd_info_${this_host}_${td}.tsv"

# /opt/xo_dc/ssds/ssds -j 

/opt/xo_dc/ssds/ssds -j \
	| jq -r '.blockdevices[] | select (.subsystems=="block:scsi:usb:pci")' \
	>> "$ssd_info_json"
printf "Written to: %s\n\n\n" "$ssd_info_json"




exit 0


/opt/xo_dc/ssds/ssds -j \
	| jq -r '.blockdevices[] | select (.subsystems=="block:scsi:usb:pci") | [.children[].label, .size, .vendor, .model, .serial] | @tsv' \
	| /usr/bin/ts "%Y-%m-%d %H:%M:%S %s" \
	| /usr/bin/tee -a "$ssd_info_tsv"
printf "Written to: %s\n\n\n" "$ssd_info_tsv"


/opt/xo_dc/ssds/ssds -j \
	| jq -r '.blockdevices[] | select (.subsystems=="block:scsi:usb:pci") | [.children[].label, .size, .vendor, .model, .serial] | @csv' \
	| /usr/bin/ts "%Y-%m-%d,%H:%M:%S,%s," \
	| sed 's/, "/,"/g' \
	| sed 's/"//g' \
	| sed 's/ '/'/g' \
	| /usr/bin/tee -a "$ssd_info_csv"
printf "Written to: %s\n\n\n" "$ssd_info_csv"


exit 0

string=$(<<'EOF' tr -d '\n'
Rerum inventore nemo neque reiciendis ullam. Vo
luptate amet eveniet corporis nostrum. Laborios
am id sapiente atque non excepturi. Dolorem ali
as sed et voluptatem est unde sed atque. Itaque
 ut molestias alias dolor eos doloremque explic
abo. Quas dolorum sint sit dicta nemo qui. 'And
'#\`"$% whatever.
EOF
)

echo $string
