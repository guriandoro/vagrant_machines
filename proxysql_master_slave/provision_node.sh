#!/bin/bash
yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release setup ps57
yum -y install tar gdb strace vim qpress socat Percona-Server-server-57
iptables -F
setenforce 0
mysqld --initialize-insecure --user=mysql
NODE_NR=$1
NODE_IP="$2"
MASTER_IP="$3"
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

        # ProxySQL users
#        mysql -e "CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor';"
#        mysql -e "GRANT USAGE ON *.* TO 'monitor'@'%';"
#        mysql -e "CREATE USER 'monitor'@'localhost' IDENTIFIED BY 'monitor';"
#        mysql -e "GRANT USAGE ON *.* TO 'monitor'@'localhost';"
#        mysql -e "CREATE USER 'app'@'%' IDENTIFIED BY 'app';"
#        mysql -e "GRANT ALL ON *.* TO 'app'@'%';"
#        mysql -e "CREATE USER 'app'@'localhost' IDENTIFIED BY 'app';"
#        mysql -e "GRANT ALL ON *.* TO 'app'@'localhost';"



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
