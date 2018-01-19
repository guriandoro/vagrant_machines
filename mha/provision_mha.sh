#!/bin/bash
yum install -y epel-release
yum install -y git perl-DBD-MySQL perl-Module-Install perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager
iptables -F
setenforce 0

NODES=$1

cd /tmp
git clone https://github.com/yoshinorim/mha4mysql-node.git
cd mha4mysql-node
perl Makefile.PL
make
make install
cd ..
git clone https://github.com/yoshinorim/mha4mysql-manager.git
cd mha4mysql-manager
perl Makefile.PL
make
make install

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
done
mkdir -p /var/log/masterha/app1
