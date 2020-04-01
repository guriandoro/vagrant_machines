#!/bin/bash
#yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
yum -y install tar gdb strace vim percona-server-server
#yum -y install https://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm
#yum -y install tar gdb strace vim qpress socat mysql-community-server
#yum -y install tar gdb strace vim qpress socat percona-toolkit tcpdump Percona-Server-server-55
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

innodb_file_per_table=1
innodb-log-file-size = 256M
innodb-flush-log-at-trx-commit = 2
innodb-buffer-pool-size = 512M

server_id=$NODE_NR
binlog_format = ROW
log-bin=node_$NODE_NR
report_host=$NODE_IP
EOF



if [[ $NODE_NR -eq 1 ]]
then
	systemctl start mysqld
	mysql -e "CREATE USER root@'192.%' identified by 'sekret'"
	mysql -e "grant all privileges on *.* to 'root'@'192.%';"
	mysql -e "CREATE USER root@'127.0.0.1' identified by 'sekret'"
	mysql -e "SET PASSWORD FOR 'root'@'127.0.0.1' = 'sekret';"
	mysql -e "SET PASSWORD FOR 'root'@'localhost' = 'sekret';"
else

	cat << EOF >> /etc/my.cnf
read_only=1
EOF
	systemctl start mysqld

	mysql -e "CHANGE MASTER TO MASTER_HOST='$MASTER_IP', MASTER_USER='root', MASTER_PASSWORD='sekret', MASTER_LOG_FILE='node_1.000001'"
	mysql -e "START SLAVE"
fi
