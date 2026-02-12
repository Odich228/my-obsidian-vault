vim /etc/net/ifaces/enp7s1/options

cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2

vim /etc/net/ifaces/enp7s1/ipv4address
	10.1.10.2/24
vim/etc/net/ifaces/enp7s1/ipv4route
	default via 10.1.10.1

