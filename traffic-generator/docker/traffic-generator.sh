#!/bin/bash

set -f
array=(${ROUTE//;/ })
for i in "${!array[@]}"
do
    echo "GET ${array[i]}" >> targets.txt
done
touch results.bin
vegeta attack -targets=targets.txt -rate=${RATE} -duration=${DURATION} >> results.bin & tail -f results.bin | vegeta report
