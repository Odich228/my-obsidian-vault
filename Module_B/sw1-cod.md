sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/enp7s1/options 
mkdir /etc/net/ifaces/mgmt
touch /etc/net/ifaces/mgmt/options
bash -c cat <<EOF > /etc/net/ifaces/mgmt/options 
TYPE=ovsport 
BOOTPROTO=static 
CONFIG_IPV4=yes 
BRIDGE=sw1-cod 
VID=300 
EOF


hostnamectl set-hostname sw1-cod.office.ssa2026.region; exec bash
domainname cod.ssa2026.region
systemctl enable --now openvswitch
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s3
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s4
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s5
cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s6
ovs-vsctl add-br sw1-cod 
ovs-vsctl add-port sw1-cod enp7s1 trunks=100,200,300,400,500
ovs-vsctl add-port sw1-cod enp7s6 tag=300
ovs-vsctl add-port sw1-cod enp7s4 tag=100
ovs-vsctl add-port sw1-cod enp7s5 tag=200
modprobe 8021q
echo "8021q" | tee -a /etc/modules
ovs-vsctl add-bond sw1-cod bond0 enp7s2 enp7s3 bond_mode=active-backup
ovs-vsctl set port bond0 trunk=100,200,300,400,500
ovs-appctl bond/show
echo "10.1.30.2/24" > /etc/net/ifaces/mgmt/ipv4address
echo "default via 10.1.30.1" > /etc/net/ifaces/mgmt/ipv4route
systemctl restart network
ovs-vsctl set port mgmt vlan_mode=native-untagged

radius:

/etc/pam_radius_auth.conf

10.1.10.2 (Tab) P@ssw0rd (Tab) 10

/etc/pam.d/sshd

(второй строкой)

auth (Tab) sufficient (Tab) pam_radius_auth.so

/etc/pam.d/system-auth-local

(первой строкой)

auth (Tab) sufficient (Tab) pam_radius_auth.so

systemctl restart sshd

cat <<EOF > /etc/net/ifaces/mgmt/resolv.conf
  search cod.ssa2026.region
  nameserver 192.168.10.1
EOF