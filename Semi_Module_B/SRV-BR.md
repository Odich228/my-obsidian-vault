```
hostnamectl set-hostname srv-br.au.team; exec bash

echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "10.2.1.10/28" > /etc/net/ifaces/ens19/ipv4address
echo "default via 10.2.1.14" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network