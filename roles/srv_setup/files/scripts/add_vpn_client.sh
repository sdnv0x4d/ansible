#!/usr/bin/env bash

COLOR0="echo -e \\033[1;32m" # Green color
COLOR1="echo -e \\033[0;39m" # Standart color

clients_path=$1
clients_list="$(ls $1)"
clients_pass_path=$2
ip_mt=$3 # IP of Mikrotik - VPN GW
username=$4 # SSH user
domain=$5
host=$6

nextip(){
  IP=$1
  IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
  NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
  NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
}

set_new_ip(){
  local host=$1
  local hostpass=$2
  nextip $(ssh ${username}@$ip_mt -o "StrictHostKeyChecking no" -p 22 "/ppp/secret/print proplist=remote-address terse" | grep -oP 'address=\K.*' | sort -k 1n | tail -n 1)                                                             # Take biggest IP from PPP/secret list and make next ip
  ssh ${username}@$ip_mt -o "StrictHostKeyChecking no" -p 22 "/ppp/secret/add name=$host service=l2tp profile=profile1 remote-address=$NEXT_IP password=$hostpass; /ip/dns/static/add name=$host-int.$domain type=A address=$NEXT_IP"   # Add new host with new IP and new pass, also add internal DNS-record with "-int" host postfix
  echo $NEXT_IP > $clients_path
}

main(){
  if [ ! -s $clients_path ];                    # If host already with IP - skip
  then
    local hostpass="$(<"$clients_pass_path")"   # Take hosts new pass from pass_path
    set_new_ip $host $hostpass
  fi
}

main