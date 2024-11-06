#!/bin/bash
source_base='/mnt/usb_drives/ssd_445/Camera'
source_base='/mnt/usb_drives'
dest_bucket='s3://xocean-production-diagnostic-data-eu-west-2'
dest_base="${dest_bucket}/direct_upload"

ssd_num=$1
ssd_dir="ssd_${ssd_num}"
ssd_path="${source_base}/${ssd_dir}"
ssd_cam_paths=$(find  "${ssd_path}" -type d -name "Camera")
nc_path="${#ssd_cam_paths[@]}"


for (( i=0; i<$nc_path; i++ )); do
	cam_path="${ssd_cam_paths[$i]}"
	printf "Using camera path: %s\n" "$cam_path"
	printf "Dest bucket: %s\n" "$dest_bucket"
	printf "Dest path: %s\n" "$dest_base"
	source_path="$cam_path"

	if [[ -d "$source_path" ]]; then
		printf "Uploading data from: %s\n" "$source_path"
		aws s3 --profile dc_auto_camera sync "$source_path" "$dest_base"  --no-progress --output text 
	else
		printf "Source path %s does not exist.  Exiting...\n" "$source_path"
	fi
done
exit
source_path="${source_base}/${ssd_path}"



# dest_path="${dest_base}/${sub}"


function get_include_string()
{
	date_key='2024-02-27'
	include_string='USV*TERM1*TERM2*'
	include_string=$(echo $include_string | sed "s/USV/X-18/g")
	include_string=$(echo $include_string | sed "s/TERM1/Ahead/g")
	include_string=$(echo $include_string | sed "s/TERM2/${date_key}/g")
	echo $include_string
}

# aws s3 --profile dc_auto_camera sync "$source_path" 's3://xocean-production-diagnostic-data-eu-west-2/direct_upload' --dryrun

# aws s3 --profile dc_auto_camera sync "$source_base" "$dest_base"  --exclude '*' --include '*X-18*Ahead*2024-02-26*' --dryrun --output text
# aws s3 --profile dc_auto_camera sync "$source_base" "$dest_base"  --exclude '*' --include '*X-18*Ahead*2024-02-27*' --no-progress --output text
# aws s3 --profile dc_auto_camera sync "$source_base" "$dest_base"  --exclude '*' --include $include_string --no-progress --output text



function upload_cam()
{
	printf "Using camera soure base path: %s\n" "$source_base"
	src=$1
	dst=$2
	aws s3 --profile dc_auto_camera sync "$src" "$dst"
}
#--exclude '*' --include $include_string --no-progress --output text
# 's3://xocean-production-diagnostic-data-eu-west-2/direct_upload' --dryrun


exit 0
# dest_path='s3://xocean-production-diagnostic-data-eu-west-2/direct_upload'

