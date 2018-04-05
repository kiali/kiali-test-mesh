#!/bin/bash

set -f
array=(${ROUTE//;/ })
for i in "${!array[@]}"
do
    echo "GET ${array[i]}" >> targets.txt
done
vegeta attack -targets=targets.txt -rate=${RATE} -duration=${DURATION} > results.bin
cat results.bin | vegeta report
