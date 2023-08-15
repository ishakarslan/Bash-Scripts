#!/bin/bash

#If you use date based index this script deletes old indexes that you can describe as index date

PATH=/sbin:/usr/sbin:/bin:/usr/bin
export PATH

tarih=$(date --date="90 days ago" +"%Y"."%m"."%d")
es_host="https://127.0.0.1:9200"

   for i in `(curl -u elastic:your_elastic_password -XGET https://127.0.0.1:9200/_cat/indices?v --insecure|egrep  index_name-* |sort |awk '{print $3}' |cut -d '-' -f 4)`;
   #awk '{print $3}' you should select correct section as date
     do

   if [[ $i < $tarih ]];
    then
      curl -s --insecure -u elastic:your_elastic_password -XDELETE "https://127.0.0.1:9200/index_name-$i"
      #if you want to close it use below command
      #curl -s --insecure -u elastic:your_elastic_password -XPOST "https://127.0.0.1:9200/index_name-$i/_close"
      echo $i index deleted or closed
   else
      exit
   fi;
done
