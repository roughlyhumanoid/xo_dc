#!/bin/bash
# /usr/bin/virsh list --all | /usr/bin/grep datasync | /usr/bin/awk '{print $3}'
/usr/bin/virsh list --all | /usr/bin/grep -E 'datasync|Name|--' 
