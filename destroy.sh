```
#!/bin/bash
source user_openrc.sh
openstack server delete haproxy01 game01 game02 game03 --insecure
openstack floating ip list --long -f value -c ID -c Description --insecure | awk '$2 == "vm-haproxy-floating-ip" {print $1}'
openstack floating ip delete $(openstack floating ip list --long -f value -c ID -c Description --insecure | awk '$2 == "vm-haproxy-floating-ip" {print $1}'
) --insecure
openstack port delete haproxy game01 game02 game03 --insecure
openstack keypair delete Vms --insecure
