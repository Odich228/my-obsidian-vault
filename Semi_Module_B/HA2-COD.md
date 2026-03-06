```bash
hostnamectl set-hostname ha2-cod.au.team; exec bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "172.16.0.2/23" > /etc/net/ifaces/ens19/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network

