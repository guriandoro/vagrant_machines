#!/bin/bash
yum -y install yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
yum -y install tar gdb strace vim qpress socat Percona-XtraDB-Cluster-server-57

#yum -y install tar gdb strace vim qpress socat Percona-XtraDB-Cluster-client-57-5.7.16-27.19.1.el7.x86_64 Percona-XtraDB-Cluster-server-57-5.7.16-27.19.1.el7.x86_64 Percona-XtraDB-Cluster-shared-57-5.7.16-27.19.1.el7.x86_64 Percona-XtraDB-Cluster-shared-compat-57-5.7.16-27.19.1.el7.x86_64
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
innodb-buffer-pool-size = 3G
innodb_use_native_aio = 0

server_id=1
binlog_format = ROW
log_slave_updates
enforce_gtid_consistency=1
gtid_mode=on

#pxc-encrypt-cluster-traffic = ON
#early-plugin-load=keyring_file.so
#keyring-file-data=/var/lib/mysql-keyring/keyring

[sst]
streamfmt=xbstream

[xtrabackup]
#keyring-file-data=/var/lib/mysql-keyring/keyring
compress
parallel=2
compress-threads=2
rebuild-threads=2
EOF

if [[ $NODE_NR -eq 1 ]]
then
	systemctl start mysql@bootstrap

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
