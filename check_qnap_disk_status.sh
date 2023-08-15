#!/bin/bash

# This script checks qnap disk usage
# If disk usage grather then %90 it will alert by email
# Author I.Arslan

qnap_ips="$1"
threshold="90"
FLAG_FILE="/scripts/$1.qnap"

#create flag file if does not exist
if [ ! -f "$FLAG_FILE" ];then
  echo "1" > $FLAG_FILE
fi

#check disk status
usage=`ssh admin@$1 'df -h'|egrep "CACHEDEV1_DATA" |egrep -v tmpfs|egrep -oE "[0-9]{1,2}%"|cut -d "%" -f 1`
flag_status=`cat $FLAG_FILE`

#send email if usage exeeded threshold and set flag file
if [ $usage -gt $threshold ]; then
  if [ $flag_status -lt 2  ]; then
     QNAPNAME=`ssh admin@$1 'hostname'`
     echo "Qnap ($QNAPNAME) disk usage reached %$threshold please check it..." |mail -s "Qnap Disk Alert ($QNAPNAME)" -r "qnap@domain.com" -S smtp=smtp://your_smtp_server alert@domain.com
     touch $FLAG_FILE
  fi
     NEW_VALUE=$(( $(cat "$FLAG_FILE") + 1)) && echo "$NEW_VALUE" > "$FLAG_FILE"
  else
     NEW_VALUE="1" && echo "$NEW_VALUE" > "$FLAG_FILE"
fi

exit 0
