#!/bin/bash
if [ $EUID -ne 0 ]; then
	echo "This script must be run as root!"
	exit 1
fi

N=4
PREFIX="bigchaindb"

ovs-vsctl add-br ovs-br1
ifconfig ovs-br1 192.168.20.1 netmask 255.255.255.0 up
for idx in `seq 1 $N`; do
	idx2=$(($idx+1))
	ovs-docker add-port ovs-br1 eth1 $PREFIX$idx --ipaddress=192.168.20.$idx2/24
done
