#!/bin/bash


function json_to_sh {
	json_file=$1
	cat "$json_file" \
		| jq -r '. | to_entries | .[] |  [.key, .value] | @sh' \
		| sed "s/' '/=/g" \
		| sed "s/'//g" \
		| awk '{printf "export %s\n",$0}'
}

function get_json_param {
	fn=$1
	param=$2

 	cat "$fn" \
		| jq -r ".${param}"
}
