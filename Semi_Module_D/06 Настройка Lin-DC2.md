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

##### Получение keytab
###### 1. Создаем пользователя  
```
samba-tool user create dhcpduser --description="User TSIG-GSSAPI DNS over DHCP" --random-password
```
###### 2. Срок действия пароля (бессрочный)

```
samba-tool user setexpiry dhcpduser --noexpiry
```
###### 3. Добавление в группу DNSAdmins

samba-tool group addmembers DnsAdmins dhcpduser
4. Создание SPN

```
samba-tool spn add DHCP/Lin-DC2.semifinal.irpo@SEMIFINAL.IRPO dhcpduser
```

5. Экспорт в keytab файл
```
samba-tool domain exportkeytab --principal=dhcpduser@SEMIFINAL.IRPO /etc/dhcp/dhcpduser.keytab
```
6. Верные файловые права
```
chown dhcpd:dhcp /etc/dhcp/dhcpduser.keytab
chmod 400 /etc/dhcp/dhcpduser.keytab
```
7. Проверка keytab-файла
Получаем TGT

```
kinit admin@SEMIFINAL.IRPO
```

8. Создать скрипт
```
wget -P  /usr/local/bin/ https://docs.altlinux.org/ru-RU/alt-domain/11.1/html/alt-domain/images/dhcp-dyndns.sh
```
Права на исполнение
```
chmod 755 /usr/local/bin/dhcp-dyndns.sh
```
9. Отключаем chroot-зацию
control dhcpd-chroot disabled

```
cat << "EOF" > /etc/dhcp/dhcpd.conf
authoritative;
ddns-update-style none;

￼subnet 192.168.1.0 netmask 255.255.255.0 {
 option subnet-mask 255.255.255.0;
 option broadcast-address 192.168.1.255;
 option time-offset 0;
 option routers 192.168.1.1;
 option domain-name-servers 192.168.1.3, 192.168.1.2;
 option ntp-servers 192.168.1.3;
 option domain-name "semifinal.irpo";
 default-lease-time 3600;
 ￼pool {
        max-lease-time 1800;
        range 192.168.1.10 192.168.1.20;
 }
}

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);

set ClientName = pick-first-value(option host-name, config-option host-name,
client-name, noname);
log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ",
ClientName));
execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID,
ClientName);
}
on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "",
substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
log(concat("Release: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}
on expiry {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
log(concat("Expired: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, "", "0");
}
EOF

systemctl enable --now dhcpd
```

