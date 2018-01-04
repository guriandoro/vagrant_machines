# ProxySQL with PXC

This vagrant provision a proxysql instace with 3 pxc nodes.
ProxySQL scheduler is not configure yet

You can adjust the number of nodes you want for your pxc by editing `number_of_nodes` on  `Vagrantfile`
IP's are created based on `base_ip` + `first_ip` from `Vagrantfile`. For example, if you want your ups to start at 192.168.10.10 adjust the variables as follow:

```
base_ip="192.168.10."
first_ip=10
```

**Note** - First IP will be assigned to ProxySQL and following IP's to PXC nodes 

MySQL `root` password is `sekret`
