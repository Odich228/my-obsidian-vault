sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/enp7s1/options
mkdir /etc/net/ifaces/mgmt
touch /etc/net/ifaces/mgmt/options
bash -c cat <<EOF > /etc/net/ifaces/mgmt/options 
TYPE=ovsport 
BOOTPROTO=static 
CONFIG_IPV4=yes 
BRIDGE=sw2-a 
VID=300 
EOF

hostnamectl set-hostname sw2-a.office.ssa2026.region; exec bash
domainname office.ssa2026.region
systemctl enable --now openvswitch
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s3
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s4

ovs-vsctl add-br sw2-a 
ovs-vsctl add-port sw2-a enp7s1 trunks=100,200,300
ovs-vsctl add-port sw2-a enp7s2 trunks=100,200,300
ovs-vsctl add-port sw2-a enp7s3 tag=200
ovs-vsctl add-port sw2-a enp7s4 tag=200
ovs-vsctl set bridge sw2-a rstp_enable=true
ovs-vsctl set bridge sw2-a other_config:stp-protocol=rstp
ovs-vsctl set bridge sw2-a other_config:rstp-priority=1

echo "10.2.30.3/24" > /etc/net/ifaces/mgmt/ipv4address
echo "default via 10.2.30.1" > /etc/net/ifaces/mgmt/ipv4route

ovs-vsctl set port mgmt vlan_mode=native-untagged
modprobe 8021q
echo "8021q" | tee -a /etc/modules