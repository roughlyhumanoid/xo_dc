#!/bin/bash
# Dmesg
# /usr/bin/dmesg -HkTu --level=alert,crit,err,warn --decode --facility=user
sdays=$1
edays=$2

if [[ "${#sdays}" -eq 0 ]]; then
	sdays=0
	edays=0
elif [[ "${#edays}" -eq 0 ]]; then
	edays="$sdays"
fi


from_ndays="$sdays"
until_ndays=$(expr "$edays" - 1)

from=$(date -d "${from_ndays} days ago" +'%Y-%m-%d')
until=$(date -d "${until_ndays} days ago" +'%Y-%m-%d')

printf "Running from: %s, to: %s\n" "$from" "$until"

/usr/bin/dmesg -HT \
	--level=alert,crit,err,warn,notice,info,debug \
	--decode \
	--facility=user,auth,syslog,kern \
	--since "$from" \
	--until "$until"
	# '2024-11-22 20:00' \
#/usr/bin/dmesg -HkT --level=err

# Sysdig


exit 0
Supported log facilities:
    kern - kernel messages
    user - random user-level messages
    mail - mail system
  daemon - system daemons
    auth - security/authorization messages
  syslog - messages generated internally by syslogd
     lpr - line printer subsystem
    news - network news subsystem

Supported log levels (priorities):
   emerg - system is unusable
   alert - action must be taken immediately
    crit - critical conditions
     err - error conditions
    warn - warning conditions
  notice - normal but significant condition
    info - informational
   debug - debug-level messages

