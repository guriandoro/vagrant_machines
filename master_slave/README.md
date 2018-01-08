# Master Slave

This vagrant provision 1 master and 2 slaves.

You can adjust the number of slaves you want by editing `number_of_slaves` on  `Vagrantfile`
IP's are created based on `base_ip` + `first_ip` from `Vagrantfile`. For example, if you want your IPs to start at 192.168.10.10 adjust the variables as follow:

```
base_ip="192.168.10."
first_ip=10
```

MySQL `root` password is `sekret`
ProxySQL application user is `app` password is `app`
