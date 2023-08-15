#!/bin/bash

CWD="/opt/zimbra"

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

#Delete old mdb backup
su - zimbra -c "rm -f /opt/zimbra/backup/data.mdb"

#Backup ldap mdb

su - zimbra -c "mdb_copy /opt/zimbra/data/ldap/mdb/db /opt/zimbra/backup/"

#Stop zimbra services
su - zimbra -c "zmcontrol stop"

if [ $? -ne 0 ]; then
   echo "`date +"%Y-%m-%d %T"` Zimbra services could not stop"
   exit 1
fi

#sync zimbra directory to aws s3
cd $CWD
#aws s3 sync . s3://s3url/backup/zimbra --delete --exclude '/opt/zimbra/data/ldap/mdb/db/*'
rsync -e "ssh -i your_private_key -o StrictHostKeyChecking=no" -avzHP --exclude 'mdb' --delete  /opt/zimbra/ root@your_ip:/backup/zimbra/

#start zimbra services
su - zimbra -c "zmcontrol start"

echo "Zimbra backup completed"
