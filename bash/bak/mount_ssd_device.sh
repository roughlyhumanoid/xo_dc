#!/bin/bash
xdata_id=$(id -u xdata)
xsync_group_id=1002
ssd_mount_base="/mnt/usb_drives"
# sudo mount -o uid=user_id,gid=group_id,other_options device mount_point
source /home/xo-mark/scripts/ssd_mounts.sh


function is_already_mounted()
{
	ssd=$1
	mount_line=$(df -Th | grep 'exfat' | grep -i "${ssd}")
	result=$?
	
	return $result
}

function mount_ssd()
{
	ssd_num=$1
	ssd_dev_path=$2
	ssd_mount_point="${ssd_mount_base}/ssd_${ssd_num}"
	printf "Mounting %s to %s\n" "${ssd_dev_path}" "${ssd_mount_point}"

	alread_mounted=$(is_already_mounted $ssd_num)
	result=$?

	if [[ "$result" -eq 0 ]]; then
		printf "SSD %s is already mounted\n" "$ssd_num"
		return
	fi


	if [[ ! -d "${ssd_mount_point}" ]]; then 
		mkdir -p "${ssd_mount_point}"
	fi

	# sudo mount -o uid=${xdata_id},gid=${xsync_group_id}, /dev/sdd1 /mnt/usb_drives/ssd_442
	sudo mount -o uid=${xdata_id},gid=${xsync_group_id}, "${ssd_dev_path}" "${ssd_mount_point}"
}



# printf "Run: mount_ssd '445' '/dev/sde1'\n"

# /home/xo-mark/scripts/get_ssd_mounts.sh
# mount_ssd '445' '/dev/sde1'
# mount_ssd '104' '/dev/sdc1'
# /home/xo-mark/scripts/get_ssd_mounts.sh
# /device mount_point



# sudo mount /dev/sdd1 /mnt/usb_drives/ssd_442/
# sudo mount /dev/sde1 /mnt/usb_drives/ssd_445/
