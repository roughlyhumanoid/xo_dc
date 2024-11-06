#!/bin/bash
ssd=$1

ssd_fil="/tmp/${ssd}.tmp"
# ssds -s "$ssd" > "$ssd_fil"
cat "$ssd_fil" | grep -v ALL | grep -E 'xodc files only|S3:'

# for each line put metric with dimensions, ssd, mission, count, size, time
