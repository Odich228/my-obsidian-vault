vim /etc/net/ifaces/enp7s1/options
mkdir /etc/net/ifaces/mgmt
vim /etc/net/ifaces/mgmt/options
	TYPE=ovsport
	BOOTPROTO=static
	CONFIG_IPV4=yes
	BRIDGE=sw1-a
	VID=300

hostnamectl set-hostname sw1-a.office.ssa2026.region; exec bash
systemctl enable --now openvswitch
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s3
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s4
systemctl restart network
ip -br -c a
ovs-vsctl add-br sw1-a 
ovs-vsctl add-port sw1-a enp7s1 trunks=100,200,300
ovs-vsctl add-port sw1-a enp7s2 trunks=100,200,300
ovs-vsctl add-port sw1-a enp7s3 trunks=100,200,300
ovs-vsctl add-port sw1-a enp7s4 tag=100
ovs-vsctl set bridge sw1-a rstp_enable=true
ovs-vsctl set bridge sw1-a other_config:stp-protocol=rstp
ovs-vsctl set bridge sw1-a other_config:rstp-priority=0
echo "10.2.30.2/24" > /etc/net/ifaces/mgmt/ipv4address
echo "default via 10.2.30.1" > /etc/net/ifaces/mgmt/ipv4route
systemctl restart network
ovs-vsctl set port mgmt vlan_mode=native-untagged
modprobe 8021q
echo "8021q" | tee -a /etc/modules