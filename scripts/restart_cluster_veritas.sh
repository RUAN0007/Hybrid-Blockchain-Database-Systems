#!/bin/bash

N=5

if [ $# -gt 0 ]; then
	N=$1
else
	echo -e "Usage: $0 <# containers>"
	echo -e "\tDefault: $N containers"
fi

sudo ./unset_ovs_veritas.sh $N
./kill_containers_veritas.sh $N
./start_containers_veritas.sh $N
sudo ./set_ovs_veritas.sh $N