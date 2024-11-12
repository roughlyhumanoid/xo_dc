#!/bin/bash
function dots() { printf "\n"; for ((i=0;i<=5;i++));do printf ". "; sleep 1; done; printf '\n'; }

printf "\nAbout to show ssd sync status using htop.\n\nTo exit press\tq\tor\tCTRL-C\n"
dots
# sleep 3
/usr/bin/htop -F 'aws s3'
