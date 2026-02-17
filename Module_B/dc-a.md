```
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/enp7s1/options
hostname dc-a.office.ssa2026.region; exec bash
domainname office.ssa2026.region
echo "10.2.10.2/24" > /etc/net/ifaces/enp7s1/ipv4address
echo "default via 10.2.10.1" > /etc/net/ifaces/enp7s1/ipv4route
echo "nameserver 77.88.8.8" > /etc/net/ifaces/enp7s1/resolv.conf
systemctl restart network
apt-get update && apt-get install -y task-samba-dc bind bind-utils
control bind-chroot disabled
echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf
(закоментить в local.conf первую строку)

vim /etc/bind/options.conf
	tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";
	minimal-responses yes;
	category lame-servers { null; };
	(остальное any)
rm -f /etc/samba/smb.conf
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol
samba-tool domain provision
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf && vim /etc/krb5.conf

samba-tool dns add 127.0.0.1 office.ssa2026.region rtr-a A 10.2.10.1 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region rtr-a A 10.2.20.1 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region rtr-a A 10.2.30.1 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region sw1-a A 10.2.30.2 -U administrator
samba-tool dns add 127.0.0.1 office.ssa2026.region sw2-a A 10.2.30.3 -U administrator


zone "2.10.in-addr.arpa" {
        type master;
        file "2.10.in-addr.arpa";
        allow-transfer { 10.1.10.2; };
};

zone "cod.ssa2026.region" {
        type forward;
        forward only;
        forwarders { 10.1.10.2; };
};

zone "1.10.in-addr.arpa" {
        type forward;
        forward only;
        forwarders { 10.1.10.2; };
};

cp /etc/bind/zone/127.in-addr.arpa /etc/bind/zone/2.10.in-addr.arpa

vim/etc/bind/zone/1.10.in-addr.arpa
