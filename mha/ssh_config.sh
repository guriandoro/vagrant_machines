#!/bin/bash

for node in `cd .vagrant/machines/; ls -d *`;
do
	vagrant ssh $node -- sudo "ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' " &
done

wait

# add ssh passwordless on all nodes to all nodes
for node in `cd .vagrant/machines/; ls -d *`;
do
	vagrant ssh $node -- touch /home/vagrant/authorized_keys
	vagrant ssh $node -- cp /etc/hosts /home/vagrant/hosts
	for destNode in `cd .vagrant/machines/; ls -d *`;
	do
		if [[ "$destNode" == "$node" ]]
		then
			continue;
		fi
		key=`vagrant ssh $destNode -- sudo cat /root/.ssh/id_rsa.pub`
		hostname=`vagrant ssh $destNode -- hostname`
		ip=`vagrant ssh $destNode -- sudo ip addr show eth1 | grep 'inet ' | awk '{print $2}' | awk -F'/' '{print $1}'`
		vagrant ssh $node -- "echo '$key' >> /home/vagrant/authorized_keys" 
		vagrant ssh $node -- "echo '$ip $hostname' >> /home/vagrant/hosts"
	done
	vagrant ssh $node -- sudo mv /home/vagrant/authorized_keys /root/.ssh/authorized_keys
	vagrant ssh $node -- sudo chown root. /root/.ssh/authorized_keys
	vagrant ssh $node -- sudo chmod 600 /root/.ssh/authorized_keys
	vagrant ssh $node -- sudo mv /home/vagrant/hosts  /etc/hosts
	vagrant ssh $node -- sudo chown root. /etc/hosts
	vagrant ssh $node -- sudo chmod 644 /etc/hosts
	
done
