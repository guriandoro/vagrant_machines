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
	for destNode in `cd .vagrant/machines/; ls -d *`;
	do
		if [[ "$destNode" == "$node" ]]
		then
			continue;
		fi
		key=`vagrant ssh $destNode -- sudo cat /root/.ssh/id_rsa.pub`
		vagrant ssh $node -- "echo '$key' >> /home/vagrant/authorized_keys" 
	done
	vagrant ssh $node -- sudo mv /home/vagrant/authorized_keys /root/.ssh/authorized_keys
	vagrant ssh $node -- sudo chown root. /root/.ssh/authorized_keys
	vagrant ssh $node -- sudo chmod 600 /root/.ssh/authorized_keys
done
