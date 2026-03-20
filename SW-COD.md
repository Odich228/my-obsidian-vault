```
hostnamectl set-hostname sw-cod.au.team; exec bash
useradd net_admin
passwd net_admin

usermod -aG wheel net_admin
echo "net_admin ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
ip addr add 172.16.1.0/23 dev ens18
ip route add 0.0.0.0/0 via 172.16.1.254
echo "nameserver 77.88.8.8" > /etc/resolv.conf
apt-get update && apt-get install -y openvswitch
systemctl enable --now openvswitch
 sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options reboot