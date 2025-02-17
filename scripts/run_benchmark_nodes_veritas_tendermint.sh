#!/bin/bash

TSTAMP=`date +%F-%H-%M-%S`
LOGS="logs-nodes-veritas-tendermint-$TSTAMP"
mkdir $LOGS

set -x

NODES="4 8 16 32"
DRIVERS=8
THREADS=256

for N in $NODES; do
    ./restart_cluster_veritas.sh $(($N+1))
    ./start_veritas_tendermint.sh $N
    
    ADDRS="192.168.20.2:1990"
    for I in `seq 3 $N`; do
        ADDRS="$ADDRS,192.168.20.$I:1990"
    done
   
    ../bin/veritas-tendermint-bench --load-path=temp/ycsb_data/workloada.dat --run-path=temp/ycsb_data/run_workloada.dat --ndrivers=$DRIVERS --nthreads=$THREADS --veritas-addrs=$ADDRS | tee $LOGS/veritas-nodes-$N.txt 
done
sudo ./unset_ovs_veritas.sh
./kill_containers_veritas.sh
