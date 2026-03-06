```
hostnamectl set-hostname srv-hq.au.team; exec bash
sed -i "s/HOSTNAME=localhost/HOSTNAME=srv-hq.au.team/g" /etc/sysconfig/network

echo "TYPE=eth" > /etc/net/ifaces/ens18/options
echo "10.1.1.10/27" > /etc/net/ifaces/ens18/ipv4address
echo "default via 10.1.1.1" > /etc/net/ifaces/ens18/ipv4route
echo "search au.team" > /etc/net/ifaces/ens18/resolv.conf
echo "nameserver 77.88.8.8" >> /etc/net/ifaces/ens18/resolv.conf
systemctl restart network