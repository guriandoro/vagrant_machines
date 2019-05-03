#!/bin/bash
yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
yum -y install epel-release
yum -y install tar gdb strace vim qpress socat Percona-Server-server-57 git perl-DBD-MySQL perl-Module-Install https://github.com/yoshinorim/mha4mysql-node/releases/download/v0.58/mha4mysql-node-0.58-0.el7.centos.noarch.rpm
iptables -F
setenforce 0
mysqld --initialize-insecure --user=mysql
NODE_NR=$1
NODE_IP="$2"
MASTER_IP="$3"
NODES="$4"
BASE_IP="$5"
FIRST_IP="$6"
#MySQL

cat << EOF > /etc/my.cnf
[mysql]
port                                = 3306
socket                              = /var/lib/mysql/mysql.sock
prompt='PXC: \u@\h (\d) > '

[client]
port                                = 3306
socket                              = /var/lib/mysql/mysql.sock


[mysqld]
socket                              = /var/lib/mysql/mysql.sock
datadir=/var/lib/mysql
user=mysql

innodb_locks_unsafe_for_binlog=1
innodb_autoinc_lock_mode=2
innodb_file_per_table=1
innodb-log-file-size = 256M
innodb-flush-log-at-trx-commit = 2
innodb-buffer-pool-size = 512M
innodb_use_native_aio = 0

server_id=$NODE_NR
binlog_format = ROW
log-bin=node_$NODE_NR
report_host=$NODE_IP
EOF



if [[ $NODE_NR -eq 1 ]]
then
	systemctl start mysql

	mysql -e "grant all privileges on *.* to 'root'@'192.%' identified by 'sekret';"
	mysql -e "grant all privileges on *.* to 'root'@'127.0.0.1' identified by 'sekret';"
	mysql -e "grant all privileges on *.* to 'root'@'localhost' identified by 'sekret';"
else

	cat << EOF >> /etc/my.cnf
read_only=1
EOF
	systemctl start mysql

	mysql -e "CHANGE MASTER TO MASTER_HOST='$MASTER_IP', MASTER_USER='root', MASTER_PASSWORD='sekret', MASTER_LOG_FILE='node_1.000001'"
	mysql -e "START SLAVE"
fi

cat << EOF >> /etc/hosts
$BASE_IP$FIRST_IP       mha
EOF

for (( i=1; i <=$NODES; i++))
do
((FIRST_IP++))
        cat << EOF >> /etc/hosts
$BASE_IP$FIRST_IP       node$i
EOF
done
mkdir -p /var/log/masterha/app1
