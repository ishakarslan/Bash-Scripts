#!/bin/bash

#This Script checks Ethereum, BSC, Tron and Avax C chain lastblock number and your Private Node last block number then compare them,
#if two block numbers are not equal then it will let you know that your node is not sync
#Author Ishak Arslan

#Variables
FLAG_FILE="/scripts/node.tmp"
FLAG_FILE2="/scripts/node2.tmp"
FLAG_FILE3="/scripts/node3.tmp"
re='^[0-9]+$'
tarih=$(date +%s)
nodetype=avax  #set your node type here
#or you can get node type as an argument
#nodetype=$1
threshold="50"

#Get private node last block number and assign it to a variable
#For Avax C Chain
if [ "$nodetype" == "avax" ];then
  nodenumber=$(echo $((`curl -s http://localhost:9650/ext/bc/C/rpc   -X POST   -H "Content-Type: application/json"   --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}'|jq|egrep '"result":'|grep -oh "\w*0x\w*"`)))
  public_api_number=$(echo $((`curl -s https://docs-demo.avalanche-mainnet.quiknode.pro/ext/bc/C/rpc   -X POST   -H "Content-Type: application/json"   --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}'|jq|egrep '"result":'|grep -oh "\w*0x\w*"`)))
  #nodenumber=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@your_node_ip -i ~/.ssh/your_private_key '/home/ubuntu/lastblock.sh')

#For BSC Node
elif [ "$nodetype"  == "bsc" ]; then  
  nodenumber=$(echo $((`curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8545|jq|egrep '"number":'|grep -oh "\w*0x\w*"`)))
  public_api_number=$(curl -s "https://api.bscscan.com/api?module=block&action=getblocknobytime&timestamp=${tarih}&closest=before&apikey=YOUR_API_KEY"|egrep -oE "[0-9]{8,15}")
  #nodenumber=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@your_node_ip -i ~/.ssh/your_private_key '/home/ubuntu/lastblock.sh')

#For ETH Node
elif [ "$nodetype"  == "eth" ];then
  nodenumber=$(echo $((`curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8545|jq|egrep '"number":'|grep -oh "\w*0x\w*"`)))
  public_api_number=$(curl -s "https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp=${tarih}&closest=before&apikey=YOUR_API_KEY"|egrep -oE "[0-9]{8,15}")
  #nodenumber=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@your_node_ip -i ~/.ssh/your_private_key '/home/ubuntu/lastblock.sh')

#For Tron Node
elif [ "$nodetype"  == "tron" ];then
  nodenumber=$(curl -s -X POST  http://127.0.0.1:8090/wallet/getnowblock|jq|egrep '"number":'|awk '{print $2}'|sed 's/,//')
  public_api_number=$(curl -s -X POST  https://api.trongrid.io/wallet/getnowblock|jq|egrep '"number":'|awk '{print $2}'|sed 's/,//')
  #nodenumber=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@your_node_ip -i ~/.ssh/your_private_key '/home/ubuntu/lastblock.sh')

else
  echo please correct the nodetype variable
  exit 1
fi

#If you want to get last block number over ssh create a file on the node server
#like /home/ubuntu/lastblock.sh and write below command into it
# echo $((`curl -s http://localhost:9650/ext/bc/C/rpc   -X POST   -H "Content-Type: application/json"   --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}'|jq|egrep '"result":'|grep -oh "\w*0x\w*"`))
#then set the variable like below
#nodenumber=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@your_node_ip -i ~/.ssh/your_private_key '/home/ubuntu/lastblock.sh')



#Check if the result is number, else alert by email
if [[  $nodenumber == ?(-)+([[:digit:]]) ]]; then
  echo `date '+%Y-%m-%d %T'` $nodetype Node  is online  >> /var/log/nodecheck.log
  #flag_status=`cat $FLAG_FILE`
  echo "1" > $FLAG_FILE
else
  flag_status=`cat $FLAG_FILE`
  #echo $flagstatus
  if [ $flag_status -lt 2  ]; then
    echo `date '+%Y-%m-%d %T'` $nodetype Node  is offline  >> /var/log/nodecheck.log
    echo "Your $nodetype Node is not raachable please check it.... '" |mail -s "Node is offline" -r "node@yourdomain.com" -S smtp=smtp://your_smpt_server_ip alert@yourdomain.com
    touch $FLAG_FILE
  fi
     NEW_VALUE=$(( $(cat "$FLAG_FILE") + 1)) && echo "$NEW_VALUE" > "$FLAG_FILE"
  fi

if [[ $public_api_number == ?(-)+([[:digit:]]) ]]; then
  echo `date '+%Y-%m-%d %T'` $nodetype Public Api  is online  >> /var/log/nodecheck.log
  #flag_status=`cat $FLAG_FILE2`
  echo "1" > $FLAG_FILE2
else
  flag_status2=`cat $FLAG_FILE2`
  if [ $flag_status2 -lt 2  ]; then
    echo `date '+%Y-%m-%d %T'` $nodetype Public Api  is offline  >> /var/log/nodecheck.log
    echo "Public Api is not reachable, please check it.... '" |mail -s "Public Api is offline" -r "node@yourdomain.com" -S smtp=smtp://your_smpt_server_ip alert@yourdomain.com
    touch $FLAG_FILE2
  fi
    NEW_VALUE=$(( $(cat "$FLAG_FILE2") + 1)) && echo "$NEW_VALUE" > "$FLAG_FILE2"
fi

#Compare results and get difference
difference=$(echo $(( $public_api_number - $nodenumber )))


#If difference more than 50 blocks between your node and Public Api then alert by email
if [ $difference -lt $threshold ]; then
  echo `date '+%Y-%m-%d %T'` $nodetype Node  is online and sync  >> /var/log/nodecheck.log
  #flag_status=`cat $FLAG_FILE3`
  echo "1" > $FLAG_FILE3
else
  flag_status3=`cat $FLAG_FILE3`
  if [ $flag_status3 -lt 2  ]; then
    echo `date '+%Y-%m-%d %T'` $nodetype Node  is not sync  >> /var/log/nodecheck.log
    echo "Your $nodetype Node is not sync.... $nodetype Public Api lastblock number is: $public_api_number, Your  $nodetype Node lastblock number is $nodenumber'" |mail -s "Node Sync Problem" -r "node@yourdomain.com" -S smtp=smtp://your_smpt_server_ip alert@yourdomain.com
    touch $FLAG_FILE3
  fi
    NEW_VALUE=$(( $(cat "$FLAG_FILE3") + 1)) && echo "$NEW_VALUE" > "$FLAG_FILE3"
fi

exit 0
