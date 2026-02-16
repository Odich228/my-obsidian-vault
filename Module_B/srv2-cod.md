sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/enp7s1/options 

cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2

echo "10.1.10.3/24" >  /etc/net/ifaces/enp7s1/ipv4address

echo "default via 10.1.10.1" > /etc/net/ifaces/enp7s1/ipv4route

echo "10.1.20.3/24" > /etc/net/ifaces/enp7s2/ipv4address

echo "default via 10.1.20.1" > /etc/net/ifaces/enp7s2/ipv4route

cat <<EOF > /etc/net/ifaces/enp7s1/resolv.conf
  search cod.ssa2026.region
  nameserver 10.1.10.2
EOF

hostnamectl set-hostname srv2-cod.cod.ssa2026.region; exec bash

domainname cod.ssa2026.region

apt-get update && apt-get install -y postgresql17-server

/etc/init.d/postgresql initdb

systemctl enable --now postgresql
