#!/bin/bash

TSTAMP=`date +%F-%H-%M-%S`
LOGS="logs-distribution-veritas-tendermint-$TSTAMP"
mkdir $LOGS

set -x

DRIVERS=8
THREADS=256
DISTROS="uniform latest zipfian"

ADDRS="http://192.168.20.2:26656,http://192.168.20.3:26656,http://192.168.20.4:26656,http://192.168.20.5:26656"

# Uniform
./restart_cluster_veritas.sh
./start_veritas_tendermint.sh
sleep 5
../bin/veritas-tendermint-bench --load-path=temp/ycsb_data/workloada.dat --run-path=temp/ycsb_data/run_workloada.dat --ndrivers=$DRIVERS --nthreads=$THREADS --veritas-addrs=192.168.20.2:1990,192.168.20.3:1990,192.168.20.4:1990,192.168.20.5:1990 | tee $LOGS/veritas-uniform.txt

# Latest
./restart_cluster_veritas.sh
./start_veritas_tendermint.sh
sleep 5
../bin/veritas-tendermint-bench --load-path=temp/ycsb_data_latest/workloada.dat --run-path=temp/ycsb_data_latest/run_workloada.dat --ndrivers=$DRIVERS --nthreads=$THREADS --veritas-addrs=192.168.20.2:1990,192.168.20.3:1990,192.168.20.4:1990,192.168.20.5:1990 | tee $LOGS/veritas-latest.txt

# Zipfian
./restart_cluster_veritas.sh
./start_veritas_tendermint.sh
sleep 5
../bin/veritas-tendermint-bench --load-path=temp/ycsb_data_zipfian/workloada.dat --run-path=temp/ycsb_data_zipfian/run_workloada.dat --ndrivers=$DRIVERS --nthreads=$THREADS --veritas-addrs=192.168.20.2:1990,192.168.20.3:1990,192.168.20.4:1990,192.168.20.5:1990 | tee $LOGS/veritas-zipfian.txt

./stop_veritas_tendermint.sh
