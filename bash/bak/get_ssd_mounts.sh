#!/bin/bash
function get_ssd_mounts()
{
	/usr/bin/lsblk -o SUBSYSTEMS,LABEL,PARTLABEL,TYPE,NAME,PATH,MOUNTPOINT | grep usb | grep part | awk '{print $2,$3,$7,$8,$NF}'
}

get_ssd_mounts

