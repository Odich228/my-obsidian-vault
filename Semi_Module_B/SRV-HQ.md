```
hostnamectl set-hostname srv-hq.au.team; exec bash
sed -i "s/HOSTNAME=localhost/HOSTNAME=srv-hq.au.team/g" /etc/sysconfig/network

echo "TYPE=eth" > /etc/net/ifaces/enp6s18/options
echo "10.1.1.10/27" > /etc/net/ifaces/enp6s18/ipv4address
echo "default via 10.1.1.1" > /etc/net/ifacesenp6s18/ipv4route
echo "search au.team" > /etc/net/ifaces/enp6s18/resolv.conf
echo "nameserver 77.88.8.8" >> /etc/net/ifaces/enp6s18/resolv.conf
systemctl restart network
apt-get install -y haveged freeipa-server-dns
systemctl enable --now haveged
echo "10.1.1.10 srv-hq.au.team srv-hq" > /etc/hosts
ipa-server-install 
	1.-
	2.-
	3.-
	4.P@ssw0rd
	5.yes
	6.-
	7.-
	8.77.88.8.8
	9.-
	10.yes
	11.-
	12.-
	13.-
	14.yes
	15.-
	16.-
	17.yes
ipactl status  (ПРОВЕРКА)
echo "allow-query { any; };" >> /etc/bind/ipa-options-ext.conf
ipactl restart
