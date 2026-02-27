```
#!/bin/bash
source user_openrc.sh


openstack port create --network Cloud-Network --fixed-ip ip-address=192.168.100.101 haproxy --insecure
openstack port create --network Cloud-Network --fixed-ip ip-address=192.168.100.102 game01 --insecure
openstack port create --network Cloud-Network --fixed-ip ip-address=192.168.100.104 game03 --insecure
openstack port create --network Cloud-Network --fixed-ip ip-address=192.168.100.103 game02 --insecure
openstack keypair create --public-key /home/altlinux/.ssh/id_rsa.pub Vms --insecure
openstack server create --flavor B1 --image alt-p11-cloud-x86_64 --port haproxy --boot-from-volume 10 --key-name Vms haproxy01 --insecure
openstack server create --flavor B1 --image alt-p11-cloud-x86_64 --port game01 --boot-from-volume 10 --key-name Vms game01 --insecure
openstack server create --flavor B1 --image alt-p11-cloud-x86_64 --port game02 --boot-from-volume 10 --key-name Vms game02 --insecure
openstack server create --flavor B1 --image alt-p11-cloud-x86_64 --port game03 --boot-from-volume 10 --key-name Vms game03 --insecure
openstack floating ip create --port haproxy --description vm-haproxy-floating-ip public --insecure
