
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/enp7s1/options
mkdir /etc/net/ifaces/mgmt
touch /etc/net/ifaces/mgmt/options
bash -c 'cat <<EOF > /etc/net/ifaces/mgmt/options 
TYPE=ovsport 
BOOTPROTO=static 
CONFIG_IPV4=yes 
BRIDGE=sw2-cod 
VID=300 
EOF'


echo "10.1.30.3/24" > /etc/net/ifaces/mgmt/ipv4address

echo "default via 10.1.30.1" > /etc/net/ifaces/mgmt/ipv4route
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s3
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s4
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s5
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s6
systemctl restart network


hostnamectl set-hostname sw2-cod.office.ssa2026.region; exec bash
domainname cod.ssa2026.region
systemctl enable --now openvswitch
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
ovs-vsctl add-br sw2-cod 
ovs-vsctl add-bond sw2-cod bond0 enp7s1 enp7s2 bond_mode=active-backup
ovs-appctl bond/show
ovs-vsctl add-port sw2-cod enp7s3 tag=400
ovs-vsctl add-port sw2-cod enp7s4 tag=500
ovs-vsctl add-port sw2-cod enp7s5 tag=100
ovs-vsctl add-port sw2-cod enp7s6 tag=200
modprobe 8021q
echo "8021q" | tee -a /etc/modules

ovs-vsctl set port mgmt vlan_mode=native-untagged

roo