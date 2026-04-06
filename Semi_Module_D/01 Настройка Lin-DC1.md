Понижаем домен AD:
```
set-ADForestMode -Identity samba.alt -ForestMode Windows2012R2Forest
set-ADDomainMode -Identity samba.alt -DomainMode windows2012R2Domain

set-ADForestMode -Identity samba.alt -ForestMode Windows2008R2Forest
set-ADDomainMode -Identity samba.alt -DomainMode windows2008R2Domain
```

Добавить в DNS A record
	 **Lin-DC1 192.168.1.3**


#### Базовая настройка  
	**имени**
```
hostnamectl hostname Lin-DC1.semifinal.irpo
domainname semifinal.irpo
```
	**и сети**
```
echo "TYPE=eth" > /etc/net/ifaces/enp6s18/options 
echo "192.168.1.3/24" > /etc/net/ifaces/enp6s18/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/enp6s18/ipv4route
echo -e "nameserver 192.168.1.2\nsearch semifinal.irpo" > /etc/net/ifaces/enp6s18/resolv.conf

systemctl restart network
```
#### Настройка NTP-сервера
```
control chrony server
 systemctl enable --now chronyd
 systemctl status chronyd.service
 chronyc sources
```
#### Установка бинда и самбы
```
apt-get update && apt-get install bind-utils bind task-samba-dc -y
control bind-chroot disabled
echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf

```
#### Настройка бинда
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
        listen-on { 127.0.0.1; 192.168.1.3; };
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

#### ОЧЕНЬ НАДО!!!
```
rm -f /etc/samba/smb.conf ; rm -rf /var/lib/samba ; rm -rf /var/cache/samba ; mkdir -p /var/lib/samba/sysvol
```

#### заменяешь [[Ultimate Kerberos]]

/etc/samba/smb.conf
```
 cat << "EOF" > /etc/samba/smb.conf
[global]
        dns forwarder = 8.8.8.8
        netbios name = LIN-DC1
        realm = SEMIFINAL.IRPO
        server role = active directory domain controller
        server services = -dns
        workgroup = SEMIFINAL
 ;       dsdb:schema update allowed = true
 ;       ad dc functional level = 2016
[sysvol]
        path = /var/lib/samba/sysvol
        read only = No

[netlogon]
        path = /var/lib/samba/sysvol/semifinal.irpo/scripts
        read only = No
EOF
```
#### TGT билет

```
kinit admin@SEMIFINAL.IRPO
klist
```
#### Вводим в домен
```
samba-tool domain join semifinal.irpo DC -U admin --realm=semifinal.irpo --dns-backend=BIND9_DLZ
```

#### Включаем службу
```
systemctl enable --now samba
systemctl enable --now bind
service samba status; service bind status
systemctl restart samba bind (X2) 
systemctl status samba bind 
service samba status; service bind status 

```
#### Проверка
```
host semifinal.irpo
host -t SRV _ldap._tcp.semifinal.irpo
```
смотри что бы было по две записи 

#### Проверка работы службы каталогов LDAP
```
samba-tool drs showrepl
```
#### Меняем DNS на себя
```
echo -e "nameserver 127.0.0.1\nsearch semifinal.irpo" > /etc/net/ifaces/enp6s18/resolv.conf 
systemctl restart network
```

#### Перенос политик 
```
на Win-DC открываешь два проводника
	на левом: \\Lin-DC1\sysvol\semifinal.irpo (там будет папка scripts, снеси её)
	на правом:  C:\Windows\SYSVOL\sysvol\semifinal.irpo
	Увидишь две папки Policies и scripts, переносишь на Lin-DC1

НА LIN-DC1
	samba-tool ntacl sysvolreset
```
