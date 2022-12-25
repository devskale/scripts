#!/bin/bash

#if [ $# -eq 0 ]; then
# echo "no arguments"
# exit 1
#fi

if [ -z "$1" ]
  then
    echo "Add port as argument"
    echo "addport PORTNUM"
    exit 1
fi

PORT=$1

sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport $PORT -j ACCEPT

sudo netfilter-persistent save &>/dev/null

echo "added Port $PORT"

