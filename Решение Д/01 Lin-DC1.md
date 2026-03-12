##### Базовая настройка  
	**имени**
```
hostnamectl hostname Lin-DC1.semifinal.irpo
domainname semifinal.irpo
```
	**и сети**
```
echo "TYPE=eth" > /etc/net/ifaces/ens18/options 
echo "192.168.1.3/24" > /etc/net/ifaces/ens18/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/ens18/ipv4route
echo -e "nameserver 192.168.1.2\nsearch semifinal.irpo" > /etc/net/ifaces/ens18/resolv.conf

systemctl restart network
```
##### Настройка NTP-сервера
```
control chrony server
 systemctl enable --now chronyd
 systemctl status chronyd.service
 chronyc sources
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
systemctl stop bind
##### SambaDC
samba --version
https://wiki.samba.org/index.php/Raising_the_Functional_Levels
https://docs.altlinux.org/ru-RU/alt-server/11.0/html/alt-server/raise-domain-level.html
обязательно!!
rm -f /etc/samba/smb.conf ; rm -rf /var/lib/samba ; rm -rf /var/cache/samba ; mkdir -p /var/lib/samba/sysvol
##### [[Kerberos]]
 #### Samba конфиг
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
##### TGT билет
```
kinit admin@SEMIFINAL.IRPO
klist
```
###### Вводим в домен
```
samba-tool domain join semifinal.irpo DC -U admin --realm=semifinal.irpo --dns-backend=BIND9_DLZ
```

###### Включаем службу
```
systemctl enable --now samba
systemctl enable --now bind
service samba status; service bind status
```
%% Может понадобится несколько перезагрузок сервисов - это нормально!!! %%
##### Проверка
```
host semifinal.irpo
host -t SRV _ldap._tcp.semifinal.irpo
```
%% должно по две записи, иначе передергиваем сервисы или исправляем ошибки %%
###### Проверка работы службы каталогов LDAP
```
samba-tool drs showrepl
```
###### Меняем DNS на себя
```
echo -e "nameserver 127.0.0.1\nsearch semifinal.irpo" > /etc/net/ifaces/ens18/resolv.conf 
systemctl restart network
```
