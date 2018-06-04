#!/bin/bash
yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
yum -y install tar gdb strace vim qpress socat Percona-XtraDB-Cluster-server-57
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


wsrep_cluster_name=pxc_test

wsrep_provider=/usr/lib64/libgalera_smm.so
wsrep_provider_options              = "gcs.fc_limit=500; gcs.fc_master_slave=YES; gcs.fc_factor=1.0; gcache.size=256M;"
wsrep_slave_threads = 1
wsrep_auto_increment_control        = ON

wsrep_sst_method=xtrabackup-v2
wsrep_sst_auth=root:sekret

wsrep_cluster_address=gcomm://$IPS_COMMA
wsrep_node_address=$NODE_IP
wsrep_node_name=node$NODE_NR


innodb_locks_unsafe_for_binlog=1
innodb_autoinc_lock_mode=2
innodb_file_per_table=1
innodb-log-file-size = 256M
innodb-flush-log-at-trx-commit = 2
innodb-buffer-pool-size = 512M
innodb_use_native_aio = 0

server_id=$NODE_NR
binlog_format = ROW



[sst]
streamfmt=xbstream

[xtrabackup]
compress
parallel=2
compress-threads=2
rebuild-threads=2
EOF

if [[ $NODE_NR -eq 1 ]]
then
	systemctl start mysql@bootstrap

	# ProxySQL users
	mysql -e "CREATE USER 'monitor'@'%' IDENTIFIED BY 'monit0r';"
	mysql -e "GRANT USAGE ON *.* TO 'monitor'@'%';"
	mysql -e "CREATE USER 'monitor'@'localhost' IDENTIFIED BY 'monit0r';"
	mysql -e "GRANT USAGE ON *.* TO 'monitor'@'localhost';"
	mysql -e "CREATE USER 'app'@'%' IDENTIFIED BY 'app';"
	mysql -e "GRANT ALL ON *.* TO 'app'@'%';"
	mysql -e "CREATE USER 'app'@'localhost' IDENTIFIED BY 'app';"
	mysql -e "GRANT ALL ON *.* TO 'app'@'localhost';"

	mysql -e "grant all privileges on *.* to 'root'@'192.%' identified by 'sekret';"
	mysql -e "grant all privileges on *.* to 'root'@'127.0.0.1' identified by 'sekret';"
	mysql -e "grant all privileges on *.* to 'root'@'localhost' identified by 'sekret';"
else
	for i in {1..60}
	do
		MYSQLADMIN=`mysqladmin -uroot -psekret -h$BOOTSTRAP_IP ping`
		if [[ "$MYSQLADMIN" == "mysqld is alive" ]]
		then 
			systemctl start mysql
			exit
		else
			sleep 5
		fi
	done
fi
