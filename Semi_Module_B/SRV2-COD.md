```bash
hostnamectl set-hostname srv2-cod.au.team 
echo "TYPE=eth" > /etc/net/ifaces/enp6s18/options
echo "172.16.1.2/23" > /etc/net/ifaces/enp6s18/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/enp6s18/ipv4route
echo "search au.team" > /etc/net/ifaces/enp6s18/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/enp6s18/resolv.conf
systemctl restart network

exec bash