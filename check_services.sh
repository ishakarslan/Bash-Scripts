#!/bin/bash

# This script checks wazuh elk etc... services
# Author I.Arslan

SERVICE="filebeat elasticsearch wazuh-manager suricata nginx"

for i in $SERVICE; do STATUS="$(systemctl is-active $i.service)"
if [ "${STATUS}" = "active" ]; then
   echo $i running > /dev/null 2&>1
   echo "0" > /tmp/$i.tmp
else
    systemctl restart $i.service
    SRVSTATE=`cat /tmp/$i.tmp`
    if [ "${SRVSTATE}" = "0" ];then
      echo $i not running
      echo "$i Service restarted, Please check it" |mail -s "$i Servis Error" -r "service_check@domain.com" -S smtp=smtp://your_smtp_server alert@domain.com
      echo "1" > /tmp/$i.tmp
    else
       echo "Notification email has already sent"
    fi

fi
done
