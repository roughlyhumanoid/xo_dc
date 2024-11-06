#!/bin/bash
# cat /var/log/xocean_data_centre/automount.log | grep -iE 'attempting|Creating|Going|Mounting|Unspported'
cat /var/log/xocean_data_centre/automount.log | grep -iE 'Creating|Mounting|Unspported'
