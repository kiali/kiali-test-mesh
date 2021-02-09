#!/bin/bash

set -f
array=(${ROUTE//;/ })
for i in "${!array[@]}"
do
    echo "GET ${array[i]}" >> targets.txt
done

if [ "${SILENT}" = "true" ]
then
  vegeta attack -targets=targets.txt -rate=${RATE} -duration=${DURATION} -insecure > /dev/null
else
  touch results.json
  vegeta attack -targets=targets.txt -rate=${RATE} -duration=${DURATION} -insecure >> results.json &
  sleep 3
  while true; do
     vegeta report results.json
     sleep 2
     echo ""
     echo ""
  done

fi
