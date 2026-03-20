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
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
reboot
rm -rf /etc/net/ifaces/enp6s18/options
echo "TYPE=eth" >> /etc/net/ifaces/enp6s18/options
cat /etc/net/ifaces/enp6s18/options
cp -r /etc/net/ifaces/enp6s{18,19}
cp -r /etc/net/ifaces/enp6s{18,20}
cp -r /etc/net/ifaces/enp6s{18,21}
cp -r /etc/net/ifaces/enp6s{18,22}
cp -r /etc/net/ifaces/enp6s{18,23}
systemctl restart network
ovs-vsctl add-br sw-cod
ovs-vsctl add-port sw-cod ens18
ovs-vsctl add-port sw-cod ens19
ovs-vsctl add-port sw-cod ens20
ovs-vsctl add-port sw-cod ens21
ovs-vsctl add-port sw-cod ens22
ovs-vsctl add-port sw-cod ens23