#!/bin/bash
s3='s3://xocean-production-raw-dc-eu-west-2/DC1'
r1='$RECYCLE.BIN'

ssd=$1
ssd_label="ssd_${ssd}"
del_target="${s3}

aws s3 ls 's3://xocean-production-raw-dc-eu-west-2/DC1/ssd_208/$RECYCLE.BIN' --recursive --dryrun
aws s3 rm 's3://xocean-production-raw-dc-eu-west-2/DC1/ssd_208/$RECYCLE.BIN' --recursive --dryrun
aws s3 rm 's3://xocean-production-raw-dc-eu-west-2/DC1/ssd_208/$RECYCLE.BIN' --recursive 
aws s3 ls s3://xocean-production-raw-dc-eu-west-2/DC1/ssd_208/
