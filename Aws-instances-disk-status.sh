#!/bin/bash

##Get AWS instances, Private Addresses, Names, Os and Ssh ports
##I manually tagged Os and SSH ports

instance=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"  --query 'Reservations[*].Instances[*].[PrivateIpAddress, Platform, Tags[?Key==`Name`]| [0].Value,Tags[?Key==`Os`]| [0].Value,Tags[?Key==`Port`]| [0].Value]' --output table|egrep -v windows|sed -e '/^\+/d' -e '/^\-/d' -e 's/|//g' -e "s/\'//"|tail -n +2|awk '{print $1 " " $3 " " $4 " " $5}')

#Assign custom SSH usernames and SSH ports in while loop and get disk status
while IFS= read -r line; do
    host=$(echo $line|awk '{print $1}')
    hostname=$(echo $line|awk '{print $2}')
    sshport="22" #default
    if [ $(echo $line|awk '{print $3}') = centos  ]; then
       user="centos"
    elif [ $(echo $line|awk '{print $3}') = ubuntu  ]; then
       user="ubuntu"
    else
       user="ec2-user"
    fi
    if [ $(echo $line|awk '{print $4}') != None  ]; then
       sshport=$(echo $line|awk '{print $4}')
    fi

    echo -e "-------------------------------------"
    echo $hostname
    ssh -o ConnectTimeout=5 -i ~/.ssh/your_private_key -o StrictHostKeyChecking=no  -p$sshport $user@$host "df -H | grep -vE '^Filesystem|tmpfs|cdrom|loop|udev'" </dev/null| awk '{ print $5 " " $1 " " $6 }'
done <<< "$instance"
