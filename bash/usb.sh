#!/bin/bash
function dump_all()
{
	lsusb
	lspci
	usv-devices
}


function list_buses()
{
	printf "\nAll buses, all devices.\n"
	lsusb -v 2> /dev/null | grep -i Bus | grep Device

	printf "\nBus 001, all devices.\n"
	lsusb -s 001: -v 2> /dev/null | grep -i Bus | grep Device

	printf "\nBus 002, all devices.\n"
	lsusb -s 002: -v 2> /dev/null | grep -i Bus | grep Device
}

printf "\n--- Connected bus powered devices - San disks ---\n"
tmp_fil=/tmp/usb_tmp.fil
lsusb -v 2> /dev/null | grep -iE 'Bus Powered|Bus' | grep 'Bus Powered' -B 1 | grep Device > ${tmp_fil} 
# cat $tmp_fil

readarray -t ssds -d EOF < $tmp_fil
ns=${#ssds[@]}
a=8; b=10; c=12; d=40
# Bus 001 Device 009: ID 0781:55af SanDisk Corp. Extreme Pro 55AF
printf "%-${a}s %-${b}s %-${c}s %-${d}s\n" "Bus" "Device" "Id" "Description"
for (( i=0; i<$ns; i++ )); do
	bus=$(echo ${ssds[$i]} | awk '{print $2}')
	device=$(echo ${ssds[$i]} | awk '{print $4}' | sed 's/://g')
	id=$(echo ${ssds[$i]} | awk '{print $6}')
	descr=$(echo ${ssds[$i]} | awk  '{for (i=7;i<NF;i++)printf "%s ",$i};{printf "%s\n",$NF}')
	printf "%-${a}s %-${b}s %-${c}s %-${d}s\n" $bus $device $id "$descr"
	# printf "%-10s %-8s %-10s %-50s\n" "$i"    "${usv}" "${ext_array[$i]}" "${path_array[$i]}"
done

# lsblk --tree -O --json
lsblk --tree -o TYPE,NAME,SIZE,OWNER,GROUP,MODE,SERIAL,PATH,MAJ:MIN,FSTYPE,FSSIZE,FSUSED,FSUSE%,FSROOTS | grep -E 'disk|part'





# arr=()
# for line in $(cat example.txt); do
#     arr+=("$line")
# done
# mapfile -t array_example < example.txt
# readarray -t ssds <<< 
