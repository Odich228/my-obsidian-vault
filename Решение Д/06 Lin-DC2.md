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
##### [[Kerberos]]
 #### Samba конфиг
 /etc/samba/smb.conf
 
 
```
 cat << "EOF" > /etc/samba/smb.conf
[global]
        dns forwarder = 8.8.8.8
        netbios name = LIN-DC2
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
##### Проверка
```host semifinal.irpo
host -t SRV _ldap._tcp.semifinal.irpo
```
%% должно по две записи, иначе передергиваем сервисы или исправляем ошибки %%
Проверка работы службы каталогов LDAP
```
samba-tool drs showrepl
```
Меняем DNS на себя
```
echo -e "nameserver 127.0.0.1\nsearch semifinal.irpo" >/etc/net/ifaces/ens18/resolv.conf 
systemctl restart network
```

Устанавливаем DHCP сервер
```
apt-get install dhcp-server -y
```
Убираем шрутизацию
```
control dhcpd-chroot disabled
```
Конфиг [[dhcpd.conf]]
Берем [скрипт](https://docs.altlinux.org/ru-RU/alt-domain/11.1/html/alt-domain/images/dhcp-dyndns.sh) или [[dhcp-dyndns.sh]]
```
wget -P  /usr/local/bin/ https://docs.altlinux.org/ru-RU/alt-domain/11.1/html/alt-domain/images/dhcp-dyndns.sh

chmod 755 /usr/local/bin/dhcp-dyndns.sh
```

1. На Win-DC создаем пользователя dhcpduser, пароль - не ограничен
2. Добавляем в группу DNSAdmins
3. Создаем SPN
```
setspn -A DHCP/Lin-DC2.semifinal.irpo dhcpduser
```
или
```
ktpass -princ DHCP/Lin-DC2.semifinal.irpo@SEMIFINAL.IRPO -mapuser dhcpduser -pass P@ssw0rd -ptype KRB5_NT_PRINCIPAL -out C:\dhcpduser.keytab
```


