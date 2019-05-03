#!/bin/bash
yum install -y epel-release
yum install -y git perl-DBD-MySQL perl-Module-Install perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager https://github.com/yoshinorim/mha4mysql-manager/releases/download/v0.58/mha4mysql-manager-0.58-0.el7.centos.noarch.rpm https://github.com/yoshinorim/mha4mysql-node/releases/download/v0.58/mha4mysql-node-0.58-0.el7.centos.noarch.rpm
iptables -F
setenforce 0

NODES=$1
BASE_IP=$2
FIRST_IP=$3

cat << EOF > /etc/app1.cnf
[server default]
  # mysql user and password
  user=root
  password=sekret
  # working directory on the manager
  manager_workdir=/var/log/masterha/app1
  # manager log file
  manager_log=/var/log/masterha/app1/app1.log
  # working directory on MySQL servers
  remote_workdir=/var/log/masterha/app1
  #replication password
  repl_password=sekret
  log_level=debug
EOF

for (( i=1; i <=$NODES; i++))
do
	cat << EOF >> /etc/app1.cnf
  [server$i]
  hostname=node$i
EOF
((FIRST_IP++))
	cat << EOF >> /etc/hosts
$BASE_IP$FIRST_IP	node$i
EOF
done
mkdir -p /var/log/masterha/app1
