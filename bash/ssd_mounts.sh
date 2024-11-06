#!/bin/bash
xdata_id=$(id -u xdata)
xsync_group_id=1002
ssd_mount_base="/mnt/usb_drives"
dryrun=1
# sudo mount -o uid=user_id,gid=group_id,other_options device mount_point
# source /home/xo-mark/scripts/ssd_mounts.sh

function get_ssd_mounts()
{
	/usr/bin/lsblk -o SUBSYSTEMS,LABEL,PARTLABEL,TYPE,NAME,PATH,MOUNTPOINT | grep usb | grep part | awk '{print $2,$3,$7,$8,$NF}'
}

function get_ssds()
{
	readarray -t ssd_list <<< $(get_ssd_mounts | awk '{print $2}')
	echo ${ssd_list[*]}
	# echo "${ssd_list[*]}"
	# echo ${ssd_list[*]}
	# echo "${ssd_list[@]}"
	# echo ${ssd_list[@]}
	# n=${#ssd_list}
	# echo $n
	# return "${ssd_list[@]}"
}


function loop_ssds()
{
	# ssd_list="${1[@]}"
	ssd_list=$(get_ssds)
	echo "${ssd_list[0]}"

	ns="${#ssd_list[@]}"
	# echo $ns


	for ((i=0; i<$ns; i++ )); do
		echo $i
		this_ssd=${ssd_list[$i]}
		printf "Checking SSD %s\n" "$this_ssd"
	done
}



function is_already_mounted()
{
	ssd=$1
	mount_line=$(df -Th | grep 'exfat' | grep -i "${ssd}")
	result=$?
	
	return $result
}

function print_mount_ssd_help()
{
	printf "mount_ssd 442 /dev/sdz9"
}

function mount_ssd()
{
	if [[ -z "$1" ]]; then print_mount_ssd_help; return; fi
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
	sudo mount -t exfat -o uid=${xdata_id},gid=${xsync_group_id}, "${ssd_dev_path}" "${ssd_mount_point}"
}


# loop_ssds
printf "get_ssds\n"
printf "mount_ssd 442 /dev/sdz9\n"
printf "is_already_mounted 442\n"
# printf "Run: mount_ssd '445' '/dev/sde1'\n"

# /home/xo-mark/scripts/get_ssd_mounts.sh
# mount_ssd '445' '/dev/sde1'
# mount_ssd '104' '/dev/sdc1'
# /home/xo-mark/scripts/get_ssd_mounts.sh
# /device mount_point



# sudo mount /dev/sdd1 /mnt/usb_drives/ssd_442/
# sudo mount /dev/sde1 /mnt/usb_drives/ssd_445/
