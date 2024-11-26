#!/bin/bash
backup_base=/backup
backup_dir="${backup_base}/log_backup"

function getLM {
	f=$1
	dt=$(stat "$f"  --format %y  | awk '{print $1}')
	echo "$dt"
}

export -f getLM


readarray -t dm_files <<< $(find /var/log -maxdepth 1 -type f -name "dmesg*" | sort)

nf="${#dm_files[@]}"

for (( i=0;i<"$nf";i++ )); do 
	f="${dm_files[$i]}"
	fn=$(basename $f)
	dt=$(getLM "$f")
	new_file="${backup_dir}/${fn}_${dt}"
	cp -a "$f" "$new_file"	
done

rsync /var/log/* --include "dmesg*" --exclude "*" /backup/log_backup/ -v

