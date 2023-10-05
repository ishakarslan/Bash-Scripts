#!/bin/bash

#This script checks zimbra services, if a service is not running it will alert by email.


OIFS=${IFS}

IFS=$'
'

if [[ $EUID -ne 0 ]];then
   echo "Plase run as root"
   exit 1
fi

#Check Running Services
running=($(su - zimbra -c "zmcontrol status"| grep Running | awk '{ print $1 }'))

#Get installed services count
serviceLen=($(su - zimbra -c "zmcontrol status"|tail -n +2 |wc -l))

#echo $serviceLen

#Get running services count
arrayLen=${#running[@]}

#echo "Number of running services : ${arrayLen}"
for (( i=0; i < ${arrayLen}; i++ ));
do

  echo "Service ${running[$i]} is running"

done

#if running services count is not equal to total zimbra services then find not running services
if [[ ${arrayLen} -eq $serviceLen ]]; then
   exit 0
else
   notrunning=($(su - zimbra -c "zmcontrol status"| grep "not running" | awk '{ print $1 }'))
   notrunningLen=${#notrunning[@]}

   #add not runing services to list
   for (( i=0; i < ${notrunningLen}; i++ ));
   do
       echo "SERVICE ${notrunning[$i]} IS NOT RUNNING" >> /tmp/notrunning.txt
   done

     #Send not running services list as email
     echo -e "Zimbra  service error, Please check it...;\n`cat /tmp/notrunning.txt`" |\
     mail -s "Zimbra Service Problem" -S smtp=your_smtp_server -r "Zimbra Alert<zimbra@domain.com>"\
     alert@domain.com

     #remove list
     rm -f /tmp/notruninng.txt
fi

IFS=${OIFS}
