#!/bin/bash

#yum -y install tar gdb strace vim qpress socat git wget
#yum -y groupinstall "Development Tools"
yum -y install vim socat qpress

yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release enable-only pxc-80
percona-release enable tools release
yum -y install percona-xtradb-cluster sysbench

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
datadir                             = /var/lib/mysql
user                                = mysql

wsrep_cluster_name=pxc_test
wsrep_provider=/usr/lib64/libgalera_smm.so
wsrep_provider_options              = "gcs.fc_limit=500; gcs.fc_master_slave=YES; gcs.fc_factor=1.0; gcache.size=256M;"
wsrep_slave_threads = 1
wsrep_auto_increment_control        = ON
wsrep_sst_method=xtrabackup-v2
wsrep_cluster_address=gcomm://$IPS_COMMA
wsrep_node_address=$NODE_IP
wsrep_node_name=node$NODE_NR

innodb_autoinc_lock_mode = 2
innodb_file_per_table = 1
innodb-log-file-size = 256M
innodb-flush-log-at-trx-commit = 2
innodb-buffer-pool-size = 3G
innodb_use_native_aio = 0

server_id = 1
binlog_format = ROW
log_slave_updates
enforce_gtid_consistency = 1
gtid_mode = on

pxc-encrypt-cluster-traffic = OFF
#early-plugin-load = keyring_file.so
#keyring-file-data = /var/lib/mysql-keyring/keyring

[sst]
streamfmt = xbstream

[xtrabackup]
#keyring-file-data = /var/lib/mysql-keyring/keyring
compress
parallel = 2
compress-threads = 2
rebuild-threads = 2
EOF

if [[ $NODE_NR -eq 1 ]]
then
  systemctl start mysql@bootstrap
  mysql -e "create user 'root'@'192.%' identified by 'sekret'"
  mysql -e "create user 'root'@'127.0.0.1' identified by 'sekret'"
  mysql -e "create user 'sysbench'@'localhost' identified with mysql_native_password by 'sekret'"
  mysql -e "grant all privileges on *.* to 'root'@'192.%'"
  mysql -e "grant all privileges on *.* to 'root'@'127.0.0.1'"
  mysql -e "grant all privileges on *.* to 'sysbench'@'localhost'"
else
  for i in {1..60}
  do
    MYSQLADMIN=`mysqladmin -uroot -psekret -h$BOOTSTRAP_IP ping`
    if [[ "$MYSQLADMIN" == "mysqld is alive" ]]
    then
      systemctl start mysql
      break
    else
      sleep 5
    fi
  done
fi

echo "Creating ~/.my.cnf file"
cat >/home/vagrant/.my.cnf <<EOF
[client]
user=root
password=''
EOF

cp /home/vagrant/.my.cnf ~/.my.cnf

echo "Creating ~/run_sysbench.sh file"
cat >/home/vagrant/run_sysbench.sh <<EOF
#!/bin/bash
mysql -e "create schema if not exists sbtest"

for command in cleanup prepare run; do
  sysbench /usr/share/sysbench/oltp_insert.lua --mysql-socket=/var/lib/mysql/mysql.sock \\
  --mysql-user=sysbench --mysql-password=sekret --mysql-db=sbtest \\
  --time=300 --threads=1 --report-interval=1 --tables=10 --db-driver=mysql \\
  \$command
done;
EOF

cp /home/vagrant/run_sysbench.sh ~/run_sysbench.sh
chmod +x /home/vagrant/run_sysbench.sh ~/run_sysbench.sh

