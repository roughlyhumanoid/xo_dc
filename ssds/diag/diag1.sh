#!/bin/bash
sd=/opt/xo_dc/ssds

"${sd}/ssds" -j  \
	| jq -r .'blockdevices[] | [.name, .label, .size, .subsystems] | @tsv' \
	| grep -i 'usb'

"${sd}/ssds" list -v | sort -k4 
