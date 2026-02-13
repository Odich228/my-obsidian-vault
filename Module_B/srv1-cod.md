sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/enp7s1/options 

cp -r /etc/net/ifaces/enp7s1 /etc/net/ifaces/enp7s2
echo "10.1.10.2/24" >  /etc/net/ifaces/enp7s1/ipv4address
echo "default via 10.1.10.1" > /etc/net/ifaces/enp7s1/ipv4route
echo "10.1.20.3/24" > /etc/net/ifaces/enp7s2/ipv4address
echo "default via 10.1.20.1" > /etc/net/ifaces/enp7s2/ipv4route
echo "nameserver 77.88.8.8" > /etc/net/ifaces/enp7s1/resolv.conf

hostnamectl set-hostname srv1-cod.cod.ssa2026.region; exec bash
обновляем систему, скачиваем радиус(freeradius freeradius-utils) и бинд(bind bind-utils)

**Радиус**


меняем параметры для бинда 
	listen-on { any; };
    isten-on-v6 { none; };
    forward first;
    forwarders { 100.100.100.100; };
    allow-query { any; };
    allow-query-cache { any; };
    allow-recursion { any; };

vim /etc/bind/local.conf

cp /etc/bind/zone/localhost /etc/bind/zone/cod.ssa2026.region
chown root:named /etc/bind/zone/cod.ssa2026.region
vim /etc/bind/zone/cod.ssa2026.region
	$TTL    1D
	@       IN      SOA     cod.ssa2026.region. root.cod.ssa2026.region. (
	                IN      NS      cod.ssa2026.region.
	                IN      A       10.1.10.2
	rtr-cod         IN      A       192.168.1.1
	fw-cod          IN      A       10.1.10.1
	sw1-cod         IN      A       10.1.30.2
	sw2-cod         IN      A       10.1.30.3
	cli-cod         IN      A       10.1.40.2
	srv1-cod        IN      A       10.1.10.2
	srv2-cod        IN      A       10.1.10.3
	sip-cod         IN      A       10.1.50.2
	admin-cod       IN      A       10.1.30.4
	monitoring      IN      CNAME   srv1-cod.cod.ssa2026.region.

cp /etc/bind/zone/localhost /etc/bind/zone/1.10in-addr.arpa
chown root:named /etc/bind/zone/1.10.in-addr.arpa
vim/etc/bind/zone/1.10.in-addr.arpa
	                IN      NS      cod.ssa2026.region.
	1.10            IN      PTR     fw-cod.cod.ssa2026.region.
	2.10            IN      PTR     srv1-cod.cod.ssa2026.region.
	3.10            IN      PTR     srv2-cod.cod.ssa2026.region.
	2.30            IN      PTR     sw1-cod.cod.ssa2026.region.
	3.30            IN      PTR     sw2-cod.cod.ssa2026.region.
	4.30            IN      PTR     admin-cod.cod.ssa2026.region.
	2.40            IN      PTR     cli-cod.cod.ssa2026.region.
	2.50            IN      PTR     sip-cod.cod.ssa2026.region.

systemctl enable --now bind
vim /etc/net/ifaces/enp7s1/resolv.conf
  search cod.ssa2026.region
  nameserver 127.0.0.1

reboot

apt-get update && apt-get install -y freeradius freeradius-utils
systemctl enable --now radiusd

vim /etc/raddb/clients.conf
	client ALL {
		ipadd = 0.0.0.0
		netmask = 0 
		secret = P@ssw0rd
	}
vim /etc/raddb/users 
	netuser Cleartext-Password := "P@ssw0rd"
		Service-Type = Administrative-User,
		Cisco-AVPair = "shell:roles=admin"
systemctl restart radiusd