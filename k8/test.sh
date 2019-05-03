#!/bin/bash
MASTER_IP="$1"
NUMBER_OF_NODES="$2"
BASE_IP=$(echo $MASTER_IP| awk -F'.' '{print $1"."$2"."$3"."}')
INCREMENT_IP=$(echo $MASTER_IP| awk -F'.' '{print $4}')
for i in `seq 1 $NUMBER_OF_NODES`;
do
echo "${BASE_IP}${INCREMENT_IP} node${i}"
let INCREMENT_IP+=1
done
