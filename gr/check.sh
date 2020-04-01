#!/bin/bash
PTDEST="./for-percona";
MYSQL="mysql -uroot -psekret ";
NODES="192.168.19.120 192.168.19.121 192.168.19.122"
[ -d "$PTDEST" ] || mkdir $PTDEST;

function check_node()
{
  NODE=$1
  { date ; time $MYSQL -h ${NODE} -e "SELECT viable_candidate,read_only,transactions_behind FROM sys.gr_member_routing_candidate_status" ; } >> $PTDEST/${NODE}.out 2>&1
}

while true; do {
 [ -f /tmp/exit-percona-monitor ] && echo "exiting loop (/tmp/exit-percona-monitor is there)" && break;
 for node in ${NODES};
 do
    check_node $node &
 done
 wait
 sleep 5
} done;
