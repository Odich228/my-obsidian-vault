```
Ставим 10 влан на интерфейс 
На SRV-HQ
hostnamectl set-hostname srv-hq.au.team; exec bash 
sed -i "s/HOSTNAME=localhost/HOSTNAME=srv-hq.au.team/g" /etc/sysconfig/network 

echo "TYPE=eth" > /etc/net/ifaces/enp6s18/options
echo "10.1.1.10/27" > /etc/net/ifaces/enp6s18/ipv4address
echo "default via 10.1.1.1" > /etc/net/ifaces/enp6s18/ipv4route
echo "search au.team" > /etc/net/ifaces/enp6s18/resolv.conf
echo "nameserver 77.88.8.8" >> /etc/net/ifaces/enp6s18/resolv.conf
systemctl restart network

apt-get update && apt-get install -y haveged
systemctl enable --now haveged
apt-get install -y freeipa-server-dns
echo "10.1.1.10 srv-hq.au.team srv-hq" > /etc/hosts

ipa-server-install -U --hostname=$(hostname) -r AU.TEAM -n au.team -p P@ssw0rd -a P@ssw0rd --setup-dns --forwarder 77.88.8.8 --auto-reverse

host srv-hq.au.team
host 10.1.1.10
host ya.ru
