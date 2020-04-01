#!/bin/bash
#yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
#percona-release setup ps80
#yum -y install tar gdb strace vim qpress socat percona-server-server
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

yum install tar gdb strace vim qpress socat mysql-community-server -y

#yum -y install tar gdb strace vim qpress socat Percona-XtraDB-Cluster-client-57-5.7.17-27.20.2.el7.x86_64 Percona-XtraDB-Cluster-server-57-5.7.17-27.20.2.el7.x86_64 Percona-XtraDB-Cluster-shared-57-5.7.17-27.20.2.el7.x86_64 Percona-XtraDB-Cluster-shared-compat-57-5.7.17-27.20.2.el7.x86_64 
#yum install -y tar gdb strace vim qpress socat Percona-XtraDB-Cluster-client-57-5.7.19-29.22.3.el7.x86_64 Percona-XtraDB-Cluster-server-57-5.7.19-29.22.3.el7.x86_64 Percona-XtraDB-Cluster-shared-57-5.7.19-29.22.3.el7.x86_64 Percona-XtraDB-Cluster-shared-compat-57-5.7.19-29.22.3.el7.x86_64 
iptables -F
setenforce 0
mysqld --initialize-insecure --user=mysql
NODE_NR=$1
NODE_IP="$2"
IPS_COMMA="$3"
BOOTSTRAP_IP="$4"
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

server_id=$NODE_NR
report-host=$NODE_IP
gtid_mode=ON
enforce_gtid_consistency=ON
master_info_repository=TABLE
relay_log_info_repository=TABLE
binlog_checksum=NONE
log_slave_updates=ON
log_bin=binlog
binlog_format=ROW
transaction_write_set_extraction=XXHASH64
plugin_load_add="group_replication.so"
group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
group_replication_start_on_boot=off
group_replication_local_address= "$NODE_IP:24901"
group_replication_group_seeds= "$IPS_COMMA"
group_replication_bootstrap_group=off
EOF

if [[ $NODE_NR -eq 1 ]]
then
	systemctl start mysqld


	mysql -e "CREATE USER 'root'@'192.%' identified by 'sekret'";
	mysql -e "grant all privileges on *.* to 'root'@'192.%'";
        mysql -e "CREATE USER 'root'@'127.0.0.1' identified by 'sekret'";
	mysql -e "grant all privileges on *.* to 'root'@'127.0.0.1';"
        mysql -e "CREATE USER 'root'@'localhost' identified by 'sekret'";
	mysql -e "grant all privileges on *.* to 'root'@'localhost';"
	mysql -e "SET PASSWORD = 'sekret'"
	#group replication
	mysql -psekret -e "SET SQL_LOG_BIN=0;
CREATE USER rpl_user@'%' IDENTIFIED WITH 'mysql_native_password' BY 'password';
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';
SET SQL_LOG_BIN=1;
CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery';"
	mysql -psekret -e "SET GLOBAL group_replication_bootstrap_group=ON;START GROUP_REPLICATION;SET GLOBAL group_replication_bootstrap_group=OFF;"
else
	for i in {1..60}
	do
		MYSQLADMIN=`mysqladmin -uroot -psekret -h$BOOTSTRAP_IP ping`
		if [[ "$MYSQLADMIN" == "mysqld is alive" ]]
		then 
			systemctl start mysqld
			mysql -e "SET SQL_LOG_BIN=0;
CREATE USER rpl_user@'%' IDENTIFIED WITH 'mysql_native_password' BY 'password';
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';
SET SQL_LOG_BIN=1;
CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery';"
        mysql -e "START GROUP_REPLICATION;"
			exit
		else
			sleep 5
		fi
	done
fi
