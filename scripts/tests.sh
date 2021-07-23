#!/usr/bin/env bash
set -e

CWD=$(pwd)
COLOR_RED='\033[1;31m'
COLOR_END='\033[0m'

yarn build

cd ./src/tigerbeetle
$CWD/zig/zig build
mv zig-out/bin/tigerbeetle $CWD
cd $CWD

function onerror {
    if [ "$?" == "0" ]; then
        rm test_tigerbeetle.log
    else
        echo -e "${COLOR_RED}"
        echo "Error running tests, here are more details (from test_tigerbeetle.log):"
        echo -e "${COLOR_END}"
        cat test_tigerbeetle.log
    fi

    for I in 0
    do
        echo "Stopping replica $I..."
    done
    kill %1
}
trap onerror EXIT

CLUSTER_ID="--cluster-id=0a5ca1ab1ebee11e"
REPLICA_ADDRESSES="--replica-addresses=3001"

for I in 0
do
    echo "Starting replica $I..."
    ./tigerbeetle $CLUSTER_ID $REPLICA_ADDRESSES --replica-index=$I > test_tigerbeetle.log 2>&1 &
done

# Wait for replicas to start, listen and connect:
sleep 1

echo ""
echo "Testing..."
node dist/test.js
echo ""
