#!/bin/bash
yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release setup ps57
yum -y install tar strace vim proxysql2 Percona-Server-client-57
iptables -F
setenforce 0
systemctl start proxysql
