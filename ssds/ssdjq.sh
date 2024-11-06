#!/bin/bash
# https://www.baeldung.com/linux/jq-json-print-data-single-line

# ssds -j | jq 'length'
clear
printf "# df -Th output below here ----------------------\n"
df -Th
printf "# df -Th output above here ----------------------\n\n"

printf "# Block device query below here -----------------\n"
num_bd=$(ssds -j | jq .'blockdevices' | jq 'length')
printf "Number of block devices: %d\n" "$num_bd"

# ssds -j | jq .'blockdevices'[] | jq '.name, .label, .size'
ssds -j | jq -r .'blockdevices[] | [.name, .label, .size, .subsystems] | @tsv'


printf "\n\nConnected USB storage devices\n"
ssds -j | jq -r .'blockdevices[] | [.name, .label, .size, .subsystems] | @tsv' | grep -i 'usb'
exit 0
ssds -j | jq keys
ssds -j | jq .[][0] | jq keys 


exit 0
ssds -j | jq .'blockdevices' | more
ssds -j | jq .[] | more
ssds -j | jq .'blockdevices' | more
ssds -j | jq .[] | more
ssds -j | jq 'keys'
ssds -j | jq .[]
ssds -j | jq .[]'length'
ssds -j | jq .[] | jq 'length'
ssds -j | jq .[] | jq 'keys'
ssds -j | jq .[][0] | jq 'keys'

