#!/bin/bash
cred_file=/etc/xocean/db/db_cred.json
source /opt/xo_dc/db/json_to_sh.sh
db_host=$(get_json_param "$cred_file" db_host)
db_port=$(get_json_param "$cred_file" db_port)
db_user=$(get_json_param "$cred_file" db_user)
db_pass=$(get_json_param "$cred_file" db_pass)
db=$(get_json_param "$cred_file" db)
printf "/usr/bin/mysql -h ${db_host} --port ${db_port} --user=${db_user} -p${db_pass} ${db}\n"

/usr/bin/mysql -h $db_host --port=${db_port} --user=$db_user -p$db_pass $db
