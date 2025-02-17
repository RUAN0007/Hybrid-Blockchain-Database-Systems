#!/bin/bash

set -x

N=4
if [ $# -gt 0 ]; then
        N=$1
else
        echo -e "Usage: $0 <# containers>"
        echo -e "\tDefault: $N containers"
fi

IMGNAME="veritas"
PREFIX="veritas"

END_IDX=$(($N+1))
PREFIX="192.168.20."

set -x

# Start MongoDB
for idx in `seq 2 $END_IDX`; do
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "killall -9 mongod; cd  && rm -rf /data/db && mkdir -p /data/db"
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "nohup /mongodb-linux-x86_64-ubuntu2004-4.4.4/bin/mongod --bind_ip_all > mongodb.log 2>&1 &"
done

# Configure Tendermint
for idx in `seq 2 $END_IDX`; do	
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "killall -9 tendermint; rm -r .tendermint; /usr/local/bin/tendermint init validator"
	for jdx in `seq 2 $END_IDX`; do
		if [ $idx -ne $jdx ]; then
			echo "," >> ids_$jdx.txt
			ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "/usr/local/bin/tendermint show-node-id" >> ids_$jdx.txt
			echo "," >> ips_$jdx.txt
		    echo $PREFIX$idx >> ips_$jdx.txt
		fi
	done
	echo "," >> validators.txt
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "cat .tendermint/config/genesis.json" | jq .validators[0] >> validators.txt
	GENESIS=`ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "cat .tendermint/config/genesis.json" | jq .genesis_time`
	echo "," >> power.txt
	echo "default" >> power.txt
done
for idx in `seq 2 $END_IDX`; do
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "killall -9 tendermint"
done
VALIDATORS=`tail +2 validators.txt | tr -d '\n' | base64 | tr -d '\n'`
POWERS=`tail +2 power.txt | tr -d '\n'`

for idx in `seq 2 $END_IDX`; do
	IDS=`tail +2 ids_$idx.txt | tr -d '\n'`
	IPS=`tail +2 ips_$idx.txt | tr -d '\n'`
	scp -o StrictHostKeyChecking=no tendermint_config.py root@$PREFIX$idx:
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "./tendermint_config.py root $GENESIS generate $VALIDATORS $POWERS $IDS $IPS"
done

rm validators.txt power.txt ids*.txt ips*.txt

# Veritas Nodes
NODES=node1
for I in `seq 1 $N`; do
        NODES="$NODES,node$I"
done

# Tendermint socket
TMSOCK1="tcp://0.0.0.0:26658"
# ABCI socket
TMSOCK2="tcp://127.0.0.1:26657"

# Start Veritas
for I in `seq 1 $N`; do
	ADDR="192.168.20.$(($I+1))"
	ssh -o StrictHostKeyChecking=no root@$ADDR "cd /; redis-server > redis.log 2>&1 &"
	ssh -o StrictHostKeyChecking=no root@$ADDR "cd /; rm -rf veritas; mkdir -p /veritas/data; nohup /bin/veritas-tendermint-mongodb --signature=node$I --parties=${NODES} --blk-size=100 --addr=:1990 --mongodb-addr=mongodb://127.0.0.1:27017 --ledger-path=veritas$I --tendermint-socket=$TMSOCK1 --abci-socket=$TMSOCK2 > veritas-$I.log 2>&1 &"
done

# Start Tendermint
for idx in `seq 2 $END_IDX`; do
	ssh -o StrictHostKeyChecking=no root@$PREFIX$idx "killall -9 tendermint; sleep 1; /usr/local/bin/tendermint start --proxy-app=$TMSOCK1 > tendermint.log 2>&1 &"
done