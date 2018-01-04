# PXC Cluster

This vagrant provision a 3 pxc node cluster.

You can adjust the number of nodes you want for your pxc by editing `number_of_nodes` on  `Vagrantfile`
IP's are created based on `base_ip` + `first_ip` from `Vagrantfile`. For example, if you want your ups to start at 192.168.10.10 adjust the variables as follow:

```
base_ip="192.168.10."
first_ip=10
```

MySQL `root` password is `sekret`
