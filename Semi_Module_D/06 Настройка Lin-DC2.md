#### Базовая настройка  
	имени
```
hostnamectl hostname Lin-DC2.semifinal.irpo
domainname semifinal.irpo
```
	и сети
```
echo "TYPE=eth" > /etc/net/ifaces/ens18/options 
echo "192.168.1.2/24" > /etc/net/ifaces/ens18/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/ens18/ipv4route
echo -e "nameserver 192.168.1.3\nsearch semifinal.irpo" > /etc/net/ifaces/ens18/resolv.conf

systemctl restart network
```

##### BIND9
```
apt-get update && apt-get install bind-utils bind task-samba-dc -y
control bind-chroot disabled
echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf
```
###### /etc/bind/options.conf

```
cat << "EOF" > /etc/bind/options.conf

options {
        version "unknown";
        directory "/etc/bind/zone";
        dump-file "/var/run/named_dump.db";
        statistics-file "/var/run/named.stats";
        recursing-file "/var/run/recursing";

        // disables the use of a PID file

        tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";

        minimal-responses yes;
        listen-on { 127.0.0.1; 192.168.1.2; };
        forward first;
        forwarders { 8.8.8.8; };
        allow-query { localnets; };
        allow-recursion { localnets; };
        max-cache-ttl 86400;
};

logging {
  category lame-servers {null;};
};
EOF
```

```
systemctl stop bind
```
##### SambaDC
 **обязательно!!**
```
 rm -f /etc/samba/smb.conf ; rm -rf /var/lib/samba ; rm -rf /var/cache/samba ; mkdir -p /var/lib/samba/sysvol
```

[[Ultimate Kerberos]]