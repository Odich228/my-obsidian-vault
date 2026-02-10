vim /etc/net/ifaces/enp7s1/options
echo "10.2.10.2/24" > /etc/net/ifaces/enp7s1/ipv4address
echo "default via 10.2.10.1" > /etc/net/ifaces/enp7s1/ipv4route
echo "nameserver 77.88.8.8" > /etc/net/ifaces/enp7s1/resovl.conf
apt-get update && apt-get install -y task-samba-dc bind bind-utils

```
control bind-chroot disabled
```

```
echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
```

```
echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf
```

vim /etc/bind/options.conf
	tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";
	minimal-responses yes;
	category lame-server { null; };

```
rm -f /etc/samba/smb.conf
```

```
rm -f /etc/samba/smb.conf
```

```
rm -rf /var/cache/samba
```

```
mkdir -p /var/lib/samba/sysvol
```



```
samba-tool dns add 127.0.0.1 office.ssa2026.region rtr-a A 10.2.10.1 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region rtr-a A 10.2.20.1 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region rtr-a A 10.2.30.1 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region sw1-a A 10.2.30.2 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region sw2-a A 10.2.30.3 -U administrator
```