#!/bin/bash
ssd=$1
printf "\nAll c2.sh\n"
ps -ef | grep -i c2.sh | grep -v 'grep' 
printf "\n# ------- #\n"

if [[ "${#ssd}" -gt 1 ]]; then
	printf "\nCamera uploads for: %s\n" "$ssd"
	ps -ef | grep -i c2.sh | grep -v 'grep' | grep $ssd
	printf "\n# ------- #\n"
fi
