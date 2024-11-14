#!/bin/bash
xdata_id=$(id -u xdata)
xsync_group_id=1002
ssd_mount_base="/mnt/usb_drives"
dryrun=1
# sudo mount -o uid=user_id,gid=group_id,other_options device mount_point
# source /home/xo-mark/scripts/ssd_mounts.sh

function is_sourced() {
   if [ -n "$ZSH_VERSION" ]; then
       case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
   else  # Add additional POSIX-compatible shell names here, if needed.
       case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
   fi
   return 1  # NOT sourced.
}


function print_ssd_help()
{
        printf "\n### %s ###\n" "$0"
        printf "\tMain automount set of scripts for detecting and mounting ssds\n"
        printf "\tSimple low level bash script.\n"
        printf "\tDo not run directly unless you wrote this AND remember what you wrote.\n"
        printf "\tloop2 is the main function that is called\n"
        printf "\tHandler is: %s\n" "$(readlink -e ./auto_mount.sh)"
        printf "\n## List of functions ##\n"
        cat $0 | grep function | grep -Ev 'grep|print' | awk '{print "\t",$0}'
}


function regex_check()
{
	pattern=$1
	smallvar=$2

	if [[ "$smallvar" =~ "$pattern" ]]; then 
		echo match
	else
		echo noope
	fi
}


function get_ssd_mounts()
{
	/usr/bin/lsblk -o SUBSYSTEMS,LABEL,PARTLABEL,TYPE,NAME,PATH,MOUNTPOINT | grep usb | grep part | awk '{print $2,$3,$7,$8,$NF}' | sort -k 2
}

function get_ssd_mounts_2()
{
	# /usr/bin/lsblk -o SUBSYSTEMS,LABEL,PARTLABEL,TYPE,NAME,PATH,MOUNTPOINT | grep usb | grep part | awk '{print $2,$3,$7,$8,$NF}' | sort -k 2
        readarray -t ssd_list <<< $(get_ssd_mounts | awk '{print $2}')
        # readarray -t dev_list <<< $(get_ssd_mounts | awk '{print $4}')
        readarray -t dev_list <<< $(/usr/bin/lsblk -o PATH,LABEL,SUBSYSTEMS,NAME,TYPE | grep usb | grep part | awk '{print $1,$2}' | sort -k 2 | awk '{print $1}')
        readarray -t name_list <<< $(/usr/bin/lsblk -o NAME,LABEL,SUBSYSTEMS,TYPE | grep usb | grep part | awk '{print $1,$2}' | sort -k 2 | awk '{print $1}')
        readarray -t serial_list <<< $(/usr/bin/lsblk -o PATH,LABEL,SUBSYSTEMS,NAME,TYPE | grep usb | grep part | awk '{print $1,$2}' | sort -k 2 | awk '{print $1}')
	i=0
	s0=5
	s1=12
	s2=15
	s3=20
	s4=20
	s5=15
	printf "\n%-${s0}s%-${s1}s%-${s2}s%-${s3}s%-${s4}s%-${s5}s\n" "ID" "SSD"     "DEVICE" " PATH" "SIZE" "MOUNT PATH"
	printf "\n%-${s0}s%-${s1}s%-${s2}s%-${s3}s%-${s4}s%-${s5}s\n" "--" "-------" "------" " ----" "----" "----------"
	# printf "\n%-${s1}s%-${s2}s%-${s3}s%-${s4}s%-${s5}s\n" "-----------" "--------------" "--------------" "---------" "----------"
	# printf "\n%-${s1}s%-${s2}s%-${s3}s%-${s4}s%-${s5}s\n" "$s1" "$s2" "$s3" "$s4" "$s5"

        for ARG in ${ssd_list[*]}; do
		mnt_dir="/mnt/usb_drives/ssd_${ARG}"

		ssd_name=$(echo "${name_list[$i]}" | xargs)
		dev_path=$(echo "${dev_list[$i]}" | xargs)
		ssd_serial="${serial_list[$i]}"
		printf "%-${s0}s%-${s1}s%-${s2}s%-${s3}s" "$i" "SSD $ARG" "$ssd_name" "$dev_path" 

		if [[ ! -d "$mnt_dir" ]]; then 
			printf "%-${s4}s%-${s5}s\t" "NAN" "DIR does not exist! $mnt_dir"
		else	
			# du -sh /mnt/usb_drives/ssd_208 | awk '{printf "%-10s%-15s\t",$1,$2}'
			/usr/bin/timeout 10 du -sh $mnt_dir | awk '{printf "%-20s%-15s\t",$1,$2}'
		fi

		printf "\n"
		((i+=1))
	done
}


function query_ssd_dev()
{
	# this_dev=/dev/sdp1
	this_dev=$1
	/usr/bin/lsblk "${this_dev}" -aO --json
}


function query_ssd_dev_by_id()
{
	# this_dev=/dev/sdp1
	this_dev_id=$1
	this_dev_line=$(get_ssd_mounts_2 | grep ^${this_dev_id})
	result=$?

	if [[ "$result" -ne 0 ]]; then printf "Error.  No device.\n"; return; fi
	this_dev=$(echo $this_dev_line | awk '{print $5}')
	# echo $this_dev
	/usr/bin/lsblk "${this_dev}" -aO --json
}


function get_ssd_details()
{
	# /usr/bin/lsblk -o LABEL,PARTLABEL,SERIAL,TYPE,NAME,PATH,MOUNTPOINT,FSTYPE,SUBSYSTEMS | grep -E 'usb|PARTLABEL' | grep -E 'part|PARTLABEL'
	/usr/bin/lsblk -o SUBSYSTEMS,LABEL,PARTLABEL,TYPE,NAME,PATH,MOUNTPOINT,FSTYPE | grep usb | grep part | awk '{print $2,$3,$7,$8,$9,$NF}' | sort -k 2
}


function get_ssds()
{
	readarray -t ssd_list <<< $(get_ssd_mounts | awk '{print $2}')

	for ARG in ${ssd_list[*]}; do
    		echo $ARG
	done
}


function ssd_all_jsons()
{
	lsblk --tree -aO --json
}


function ssd_all_header()
{
	lsblk -aO | head -n 1
}


function ssd_all()
{
        printf "\n\n### --- lsblk dump --- ###\n"
        lsblk -aO | grep -E 'disk|part' | awk '{for(i=0;i<NF;i++)printf "%s\t",$i;printf "\n\n\n"}'
        return
}


function ssd_unmount()
{
	if [[ ! -d "$mount_path" ]]; then
		printf "Mount path does not exist: %s  Nothing to unmount.  Exiting\n" "$mount_path"
		return 1
	fi

	sudo umount -l "$mount_path"
}


function loop2()
{
	upload_cam=$1

	if [[ "$upload_cam" == "no_upload" ]]; then
		run_camera_upload=1
		printf "Setting upload to no\n"
	else
		run_camera_upload=0
		printf "Setting upload to yes\n"
	fi

        get_ssd_mounts
        readarray -t ssd_list <<< $(get_ssd_mounts | awk '{print $2}')

        for ARG in ${ssd_list[*]}; do
                printf "\nChecking SSD %s...\t" "$ARG"
                is_already_mounted "$ARG"
                result=$?

                if [[ "$result" -eq 0 ]]; then
                        printf "%s is already mounted.\n" "$ARG"
                else
                        printf "\n%s is not mounted.\n" "$ARG"
                        printf "\n%s, NEW_MOUNT\n" "$ARG"
                        ssd_dev_path=$(get_ssd_device_path $ARG)
                        mount_ssd $ARG $ssd_dev_path
                        sleep 5

			if [[ "${run_camera_upload}" -eq 0 ]]; then
                        	/opt/xo_dc/camera/run_cam.sh -s "$ARG" -r
			fi
                fi

                get_ssd_attached $ARG
                ssd_attached=$?

                if [[ "$ssd_attached" -eq 0 ]]; then
                        printf "SSD attached: %s\n" "$ARG"
                else
                        printf "SSD not attached: %s.  Unmounting...\n" "$ARG"
                fi
        done

        get_ssd_mounts
}


function tidyup()
{
        mapfile -d $'\0' ssd_mounts < <(find /mnt/usb_drives -mindepth 1 -maxdepth 1 -print0)
        ns="${#ssd_mounts[@]}"

        for (( i=0; i<$ns; i++ )); do
                ssdmt="${ssd_mounts[$i]}"
                this_ssd_num=$(echo $ssdmt | awk -F '_' '{print $NF}')
                get_ssd_attached $this_ssd_num
                result=$?

                if [[ "$result" -eq 0 ]]; then
                        printf "Active   | SSD %s\tDevice attached; %s. Skipping\n" "$this_ssd_num" "$ssdmt}"
                        continue
                fi

                alread_mounted=$(is_already_mounted $ssd_num)
                mounted_result=$?

                if [[ "$result" -eq 0 ]]; then
                        printf "DETACHED | SSD %s\tMounted but Not attached.  Unmounting path: %s\n" "$this_ssd_num" "$ssdmt"
                        sleep 2
                        sudo /usr/bin/umount -l "$ssdmt"
                        sleep 5
                fi

                printf "Deleting dir: %s\n" "$ssdmt"
                sudo rmdir $ssdmt
        done
}


function check_tf()
{
        ssnum=$1
        df -Th | awk '{print $7}' | grep usb_drives | grep $ssnum > /dev/null 2>&1
        result=$?
        return $result
}


function remove_mount_dir()
{
        mntnum=$1
        mount_dir="/mnt/usb_drives/ssd_${mntnum}"

        if [[ -d "$mount_dir" ]]; then
                printf "%s exists but not mounted.  Removing...\n" "$mount_dir"
                rmdir $mount_dir
        fi
}


function tidyup_2()
{
        mapfile ssd_nums < <(get_ssds)
        ns="${#ssd_nums[@]}"

        for (( i=0; i<$ns; i++ )); do
                ssdnum=$(echo "${ssd_nums[$i]}" | xargs)
                check_tf $ssdnum
                mnt_check=$?

                if [[ "$mnt_check" -eq 0 ]]; then
                        printf "Mounted\t\t %s\n" "$ssdnum"
                else
                        printf "NOT mounted\t %s\n" "$ssdnum"
                        remove_mount_dir $ssdnum
                fi
        done
}


function get_ssd_attached()
{
        ssd=$1
        pp=$2
        mount_info=$(get_ssd_mounts | grep $ssd) #  > /dev/null)
        result=$?

        if [[ "$pp" == "-p" ]]; then
                if [[ "$result" -eq 0 ]]; then
                        printf "%s\n" "$mount_info";
                else
                        printf "${ssd} not attached.\n"
                fi
        fi

        return "$result"
}


function get_ssd_device_path()
{
        ssd=$1
        /usr/bin/lsblk -o SUBSYSTEMS,LABEL,PARTLABEL,TYPE,NAME,PATH | grep usb | grep part | grep $ssd | awk '{print $NF}'
}


function get_ssd_fstype()
{
        ssd=$1
        /usr/bin/lsblk -o FSTYPE,LABEL,TYPE,SUBSYSTEMS | grep -E 'usb|LABEL' | grep -E 'part|LABEL' | grep $ssd | awk '{print $1}'
}



function loop_ssds()
{
	ssd_list=$(get_ssds)
	ns="${#ssd_list[@]}"
	echo $ns

	for ((i=0; i<$ns; i++ )); do
		echo $i
		this_ssd="${ssd_list[$i]}"
		printf "Checking SSD %s\n" "$this_ssd"
	done
}


function is_already_mounted()
{
        ssd=$1
        pp=$2
        mount_line=$(df -Th | grep -E 'exfat|ntfs|fuseblk' | grep -i "${ssd}")
        result=$?

        if [[ "$pp" == "-p" ]]; then
                if [[ "$result" -eq 0 ]]; then
                        printf "%s\n" "$mount_line";
                else
                        printf "${ssd} not mounted.\n"
                fi
        fi

        return $result
}


function mount_ssd()
{
	ssd_num=$1
	ssd_dev_path=$2
	ssd_mount_point="${ssd_mount_base}/ssd_${ssd_num}"
	fstype=$(get_ssd_fstype $ssd_num)
	printf "%s, Attempting to mount %s to %s as file system type: %s\n" "$ssd_num" "${ssd_dev_path}" "${ssd_mount_point}" "$fstype"
	alread_mounted=$(is_already_mounted $ssd_num)
	result=$?

	if [[ "$result" -eq 0 ]]; then
		printf "%s, ALREADY_MOUNTED, SSD is already mounted\n" "$ssd_num"
		return
	else
		printf "%s, Going to mount SSD %s at device path: %s to mount point: %s\n" "$ssd_num" "$ssd_num" "$ssd_dev_path" "$ssd_mount_point"
		printf "%s, MOUNTING SSD, device path: %s, mount point: %s\n" "$ssd_num" "$ssd_num" "$ssd_dev_path" "$ssd_mount_point"
	fi

	if [[ ! -d "${ssd_mount_point}" ]]; then 
		printf "%s, CREATING mount point: %s\n" "$ssd_num" "${ssd_mount_point}"
		sudo mkdir -p "${ssd_mount_point}"
	fi

	if [[ "$fstype" == "exfat" ]]; then
		printf "%s, MOUNT_TYPE: exfat\n" "$ssd_num"
		sudo mount -o uid=${xdata_id},gid=${xsync_group_id}, "${ssd_dev_path}" "${ssd_mount_point}"
	elif [[ "$fstype" == "ntfs" ]]; then
		printf "%s, MOUNT_TYPE: ntfs, using ntfs-3g\n" "$ssd_num"
		sudo mount -t ntfs-3g -o uid=${xdata_id},gid=${xsync_group_id}, "${ssd_dev_path}" "${ssd_mount_point}"
	else
		printf "%s, MOUNT_TYPE: %s, Unsupported file system type on SSD\n" "$ssd_num" "$fstype"
		printf "%s, MOUNT_TYPE: %s, Unsupported\n" "$ssd_num" "$fstype"
	fi
}



function generic_mount_ssd()
{
        #ssd_num=$1
        ssd_dev_path=$1
        #ssd_mount_point="${ssd_mount_base}/ssd_${ssd_num}"
        #fstype=$(get_ssd_fstype $ssd_num)
        ssd_mount_point=$2
	fstype=$3
        printf "Attempting to mount %s to %s as file system type: %s\n" "${ssd_dev_path}" "${ssd_mount_point}" "$fstype"
        # alread_mounted=$(is_already_mounted $ssd_num)
        # result=$?
        printf "Going to mount SSD %s at device path: %s to mount point: %s\n" "$ssd_num" "$ssd_dev_path" "$ssd_mount_point"

        if [[ ! -d "${ssd_mount_point}" ]]; then
                printf "Creating mount point: %s\n" "${ssd_mount_point}"
                sudo mkdir -p "${ssd_mount_point}"
        fi

        if [[ "$fstype" == "exfat" ]]; then
                printf "%s, Mounting as exfat\n" "$ssd_dev_path"
                sudo mount -o uid=${xdata_id},gid=${xsync_group_id}, "${ssd_dev_path}" "${ssd_mount_point}"
        elif [[ "$fstype" == "ntfs" ]]; then
                printf "%s, Mounting as ntfs using ntfs-3g\n" "$ssd_dev_path"
                sudo mount -t ntfs-3g -o uid=${xdata_id},gid=${xsync_group_id}, "${ssd_dev_path}" "${ssd_mount_point}"
        else
                printf "%s, Unsupported file system type on SSD: %s\n" "$ssd_dev_path" "$fstype"
        fi
}


