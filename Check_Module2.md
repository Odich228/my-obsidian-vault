
# Преднастрой виртуального стенда

## Необходимые мостовые интерфейсы

![Check_Linux_Bridges_Module2](img/Check_Linux_Bridges_Module2.png)

## Виртуальный стенд

![Check_Virtual_Stand_Module2](img/Check_Virtual_Stand_Module2.png)

## Необходимый преднастрой на ВМ

### ISP:

![Check_Hardware_ISP_Module2](img/Check_Hardware_ISP_Module2.png)

В настоящий момент имеем:
- **ens19** - Магистральный провайдер (vmbr0)
- **ens20** - Сеть в сторону **FW-HQ** (vmbr1)
- **ens21** - Сеть в сторону **RTR-BR** (vmbr2)
- **ens22** - Сеть в сторону **RTR-COD** (vmbr3)
- **ens29** - Сеть в сторону **OUT-CLI** (vmbr4)

```bash
[root@localhost ~]# ip -c -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens19            UP             172.20.20.172/24 fe80::be24:11ff:fefc:5f4/64 
ens20            DOWN           
ens21            DOWN           
ens22            DOWN           
ens29            DOWN           
[root@localhost ~]# 
```

Базовая настройка:
- имя
- адресация
- forwarding

```bash
hostnamectl set-hostname ISP; exec bash
sed -i "s/HOSTNAME=localhost/HOSTNAME=ISP/g" /etc/sysconfig/network
```

```bash
mkdir /etc/net/ifaces/ens2{0,1,2,9}
echo "TYPE=eth" > /etc/net/ifaces/ens20/options
cp /etc/net/ifaces/ens2{0,1}/options
cp /etc/net/ifaces/ens2{0,2}/options
cp /etc/net/ifaces/ens2{0,9}/options
```

```bash
mkdir /etc/net/ifaces/lo{1,2}
echo "TYPE=dummy" > /etc/net/ifaces/lo1/options
cp /etc/net/ifaces/lo{1,2}/options
```

```bash
echo "63.27.19.254/23" > /etc/net/ifaces/ens20/ipv4address
echo "84.212.78.94/27" > /etc/net/ifaces/ens21/ipv4address
echo "34.95.33.254/24" > /etc/net/ifaces/ens22/ipv4address
echo "34.35.36.62/26" > /etc/net/ifaces/ens29/ipv4address
echo "192.168.255.1/32" > /etc/net/ifaces/lo1/ipv4address
echo "100.64.1.1/16" > /etc/net/ifaces/lo2/ipv4address
```

```bash
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g" /etc/net/sysctl.conf
systemctl restart network
```

Проверка:

```bash
[root@ISP ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.20.20.172/24 
ens20            UP             63.27.19.254/23 
ens21            UP             84.212.78.94/27 
ens22            UP             34.95.33.254/24 
ens29            UP             34.35.36.62/26 
lo1              UNKNOWN        192.168.255.1/32 
lo2              UNKNOWN        100.64.1.1/16 
[root@ISP ~]# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
[root@ISP ~]# 
```

Устанавливаем пакет `frr` и `iptables`:

```bash
apt-get update && apt-get install -y iptables frr
```

Настраивает `iptables` для доступа в сеть Интернет из сетей FW-HQ, RTR-BR и OUT-CLI:

```bash
iptables -t nat -A POSTROUTING -s 63.27.18.0/23 -o ens19 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 84.212.78.64/27 -o ens19 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 34.95.33.0/24 -o ens19 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 34.35.36.0/26 -o ens19 -j MASQUERADE
iptables-save >> /etc/sysconfig/iptables
systemctl enable --now iptables
```

Проверка:

```bash
[root@ISP ~]# iptables -t nat -L -n -v
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 3 packets, 228 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 3 packets, 228 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 MASQUERADE  0    --  *      ens19   63.27.18.0/23        0.0.0.0/0           
    0     0 MASQUERADE  0    --  *      ens19   84.212.78.64/27      0.0.0.0/0           
    0     0 MASQUERADE  0    --  *      ens19   34.95.33.0/24        0.0.0.0/0           
    0     0 MASQUERADE  0    --  *      ens19   34.35.36.0/26        0.0.0.0/0           
[root@ISP ~]# 
```

Настройка BGP и IS-IS:

```bash
sed -i "s/bgpd=no/bgpd=yes/g" /etc/frr/daemons
sed -i "s/isisd=no/isisd=yes/g" /etc/frr/daemons
systemctl enable --now frr
vtysh
```

```text
conf t
router isis 0
is-type level-2-only 
net 49.0001.1921.6825.5001.00
exit
interface lo1
ip route isis 0
exit
interface ens21
ip route isis 0
isis circuit-type level-2-only 
isis network point-to-point
exit
router bgp 64499
bgp router-id 192.168.255.1
no bgp ebgp-requires-policy 
neighbor 192.168.255.2 remote-as 64499
neighbor 192.168.255.2 description iBGP-to-RTR-BR
neighbor 192.168.255.2 update-source lo1
neighbor 34.95.33.33 remote-as 64499 
address-family ipv4 unicast 
network 0.0.0.0/0
network 100.64.0.0/16
neighbor 192.168.255.2 next-hop-self 
neighbor 192.168.255.2 default-originate 
neighbor 192.168.255.2 soft-reconfiguration inbound
neighbor 34.95.33.33 default-originate
exit-address-family 
end
wr mem
```

Проверка:
- `is-type level-2-only` - принудительно устанавливает тип IS-IS только для уровня 2 (backbone). В нашей топологии используется одна зона, и все маршрутизаторы работают на уровне L2. В рамках задания это обеспечивает маршрутизацию в пределах одной зоны
- `net 49.0001.1921.6825.5001.00` - задаёт сетевой заголовок (NET — Network Entity Title) для IS-IS. NET однозначно идентифицирует маршрутизатор в домене IS-IS. Структура:
	- - `49.0001` — идентификатор зоны (area). Здесь выбрана произвольная зона `0001`
	- `1921.6825.5001` — **SYSTEM ID** (6 октетов). Формируется из адреса loopback интерфейса: 192.168.255.1 преобразуется в 1921.6825.5001 (по два октета IP-адреса, дополненные нулями). Это требование ТЗ: SYSTEM ID должен соответствовать адресу loopback
	- `.00` — идентификатор процесса (всегда .00 для обычного маршрутизатора).
- `isis circuit-type level-2-only` - указывает, что данный интерфейс будет работать только как L2-канал. Это соответствует глобальной настройке `is-type level-2-only` и гарантирует, что соседство будет установлено на уровне L2
- `isis network point-to-point` - принудительно устанавливает режим работы IS-IS на интерфейсе как точка-точка (P2P). По умолчанию на широковещательных средах (Ethernet) IS-IS работает в режиме broadcast с выборами DIS. При использовании `point-to-point` исключаются задержки выборов и упрощается конфигурация

```text
ISP# show running-config 
Building configuration...

Current configuration:
!
frr version 10.2.2
frr defaults traditional
hostname ISP
log file /var/log/frr/frr.log
no ipv6 forwarding
!
interface ens21
 ip router isis 0
 isis circuit-type level-2-only
 isis network point-to-point
exit
!
interface lo1
 ip router isis 0
exit
!
router bgp 64499
 bgp router-id 192.168.255.1
 no bgp ebgp-requires-policy
 neighbor 34.95.33.33 remote-as 64499
 neighbor 192.168.255.2 remote-as 64499
 neighbor 192.168.255.2 description iBGP-to-RTR-BR
 neighbor 192.168.255.2 update-source lo1
 !
 address-family ipv4 unicast
  network 0.0.0.0/0
  network 100.64.0.0/16
  neighbor 34.95.33.33 default-originate
  neighbor 192.168.255.2 next-hop-self
  neighbor 192.168.255.2 default-originate
  neighbor 192.168.255.2 soft-reconfiguration inbound
 exit-address-family
exit
!
router isis 0
 is-type level-2-only
 net 49.0001.1921.6825.5001.00
exit
!
end
ISP# 
```

# Реализация самого задания:

Пока без формулировки конкретных пунктов, просто - где и что делаю на стенде.

## FW-HQ:

Настройка интерфейса управления, для доступа к веб-интерфейсу с **ADM-HQ**:
- **vmbr1** - для подключения к провайдеру **ISP**
- **vmbr5** - для локальной сети (маршрутизация между VLAN)

![Check_FW-HQ_Hardware_Module2](img/Check_FW-HQ_Hardware_Module2.png)

- Создаём **Ethernet-интерфейс** с именем **mgmt** и задаём IP-адрес из произвольной сети:

![Ideco_CP1](img/Ideco_CP1.png)

![Ideco_CP2](img/Ideco_CP2.png)

![Ideco_CP3](img/Ideco_CP3.png)

Результат:

![Ideco_CP4](img/Ideco_CP4.png)

## ADM-HQ:

Назначаем имя на устройство в формате FQDN (au.team).
Назначаем IP-адрес из той же сети что и **FW-HQ**:

![Check_ADM-HQ_Address](img/Check_ADM-HQ_Address.png)

Переходим в веб-интерфейс управления **FW-HQ**, обращаясь по https://10.1.0.1:8443:

![Check_WebAccess_FW-HQ](img/Check_WebAccess_FW-HQ.png)

Назначаем имя на устройство в формате FQDN (au.team).
Создаём VLAN интерфейс на основе физического и указываем VID и IP-адрес в соответствие с L2 и L3:

![FW-HQ_Create_vlan20](img/FW-HQ_Create_vlan20.png)

Результат:

![FW-HQ_Check_vlan20](img/FW-HQ_Check_vlan20.png)

Выполняем коммутацию для **ADM-HQ** в соответствие с L2:

![Switching_ADM-HQ](img/Switching_ADM-HQ.png)

Перенастраиваем IP-адрес на интерфейсе для **ADM-HQ** в соответствие с  L3:

![ADM_Check_IP](img/ADM_Check_IP.png)

Теперь доступ в веб-интерфейс управления **FW-HQ**, обращаясь по https://10.1.1.33:8443:
- выполняем вход и удаляем IP-адрес с интерфейса **mgmt**
- НО не удаляем сам интерфейс!

![FW-HQ_Delete_mgmt](img/FW-HQ_Delete_mgmt.png)

Результат:
- теперь есть соответствие как L2, так и L3

![FW-HQ_Check_mgmt](img/FW-HQ_Check_mgmt.png)

Скачаем корневой сертификат и добавим в хранилище для **ADM-HQ**:

![FW-HQ_RootCA](img/FW-HQ_RootCA.png)

```bash
mv /home/user/Загрузки/root_ca.crt /etc/pki/ca-trust/source/anchors/ && update-ca-trust
```

Результат:

![Check_FW-HQ_RootCA](img/Check_FW-HQ_RootCA.png)

Выполним добавление Ethernet-интерфейса с ролью WAN - для подключения к **ISP** в соответствие с L3:

![FW-HQ_Connect_WAN1](img/FW-HQ_Connect_WAN1.png)

Результат:

![FW-HQ_Connect_WAN2](img/FW-HQ_Connect_WAN2.png)

Для доступа к сети интернет нужно настроить Балансировку и резервирование:

![FW-HQ_Connect_WAN3](img/FW-HQ_Connect_WAN3.png)

Результат:

![FW-HQ_Connect_WAN4](img/FW-HQ_Connect_WAN4.png)

```bash
[admin@fw-hq ~]# ping -c3 my.ideco.ru
PING my.ideco.ru (158.160.183.218) 56(84) bytes of data.
64 bytes from 158.160.183.218: icmp_seq=1 ttl=53 time=19.3 ms
64 bytes from 158.160.183.218: icmp_seq=2 ttl=53 time=20.1 ms
64 bytes from 158.160.183.218: icmp_seq=3 ttl=53 time=21.5 ms

--- my.ideco.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 19.274/20.283/21.474/0.907 ms
[admin@fw-hq ~]# 
```

Добавление лицензии (результат):

![FW-HQ_Check_CA](img/FW-HQ_Check_CA.png)

Создать все необходимые VLAN в соответствие с L2 и L3 аналогично как для vlan 20 (результат):

![FW-HQ_Check_Interfaces](img/FW-HQ_Check_Interfaces.png)

Создадим учётную запись **network**, сделаем на её основе авторизацию по подсети **10.1.1.0/24**, чтобы у устройств SRV-HQ и ADM-HQ временно был доступ в сеть Интернет:
- потом разведём на различные способы авторизации и уже на основе доменных пользователей

![HQ-FW_Authorization1](img/HQ-FW_Authorization1.png)

![HQ-FW_Authorization2](img/HQ-FW_Authorization2.png)

Результат:

![HQ-FW_Authorization3](img/HQ-FW_Authorization3.png)

## SRV-HQ:

Указать тег 10 на vmbr5.

Базовая настройка:
- имя
- адресация

```bash
hostnamectl set-hostname srv-hq.au.team; exec bash
sed -i "s/HOSTNAME=localhost/HOSTNAME=srv-hq.au.team/g" /etc/sysconfig/network
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "10.1.1.10/27" > /etc/net/ifaces/ens19/ipv4address
echo "default via 10.1.1.1" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 77.88.8.8" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@srv-hq ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             10.1.1.10/27 
[root@srv-hq ~]# ip -c r
default via 10.1.1.1 dev ens19 
10.1.1.0/27 dev ens19 proto kernel scope link src 10.1.1.10 
[root@srv-hq ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.1
[root@srv-hq ~]# ping -c3 ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=53 time=38.2 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=53 time=37.6 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=53 time=38.9 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 37.638/38.266/38.922/0.524 ms
[root@srv-hq ~]# 
```

Так как SambaDC в Модуле 1, а нам нужен какой-то LDAP, для интеграции с Ideco - развернём простенький домен на FreeIPA:

```bash
apt-get update && apt-get install -y haveged
```

```bash
systemctl enable --now haveged
```

```bash
apt-get install -y freeipa-server-dns
```

```bash
echo "10.1.1.10 srv-hq.au.team srv-hq" > /etc/hosts
```

Развёртывание домена FreeIPA в интерактивном режиме:

```bash
[root@srv-hq ~]# ipa-server-install

The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.
Version 4.12.5

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the NTP client (CHRONY)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure SID generation
  * Configure the KDC to enable PKINIT

To accept the default shown in brackets, press the Enter key.

Do you want to configure integrated DNS (BIND)? [no]: yes

Enter the fully qualified domain name of the computer
on which you're setting up server software. Using the form
<hostname>.<domainname>
Example: master.example.com


Server host name [srv-hq.au.team]: 

Warning: skipping DNS resolution of host srv-hq.au.team
The domain name has been determined based on the host name.

Please confirm the domain name [au.team]: 

The kerberos protocol requires a Realm name to be defined.
This is typically the domain name converted to uppercase.

Please provide a realm name [AU.TEAM]: 
Certain directory server operations require an administrative user.
This user is referred to as the Directory Manager and has full access
to the Directory for system management tasks and will be added to the
instance of directory server created for IPA.
The password must be at least 8 characters long.

Directory Manager password: 
Password (confirm): 

The IPA server requires an administrative user, named 'admin'.
This user is a regular system account used for IPA server administration.

IPA admin password: 
Password (confirm): 

Checking DNS domain au.team., please wait ...
Do you want to configure DNS forwarders? [yes]: yes
Following DNS servers are configured in /etc/resolv.conf: 10.1.1.1
Do you want to configure these servers as DNS forwarders? [yes]: 
All detected DNS servers were added. You can enter additional addresses now:
Enter an IP address for a DNS forwarder, or press Enter to skip: 77.88.8.8
DNS forwarder 77.88.8.8 added. You may add another.
Enter an IP address for a DNS forwarder, or press Enter to skip: 
DNS forwarders: 10.1.1.1, 77.88.8.8
Checking DNS forwarders, please wait ...
Do you want to search for missing reverse zones? [yes]: yes
Checking DNS domain 1.1.10.in-addr.arpa., please wait ...
Do you want to create reverse zone for IP 10.1.1.10 [yes]: 
Please specify the reverse zone name [1.1.10.in-addr.arpa.]: 
Checking DNS domain 1.1.10.in-addr.arpa., please wait ...
Using reverse zone(s) 1.1.10.in-addr.arpa.
Trust is configured but no NetBIOS domain name found, setting it now.
Enter the NetBIOS name for the IPA domain.
Only up to 15 uppercase ASCII letters, digits and dashes are allowed.
Example: EXAMPLE.


NetBIOS domain name [AU]: 

Do you want to configure CHRONY with NTP server or pool address? [no]: yes
Enter NTP source server addresses separated by comma, or press Enter to skip: 
Enter a NTP source pool address, or press Enter to skip: 

The IPA Master Server will be configured with:
Hostname:       srv-hq.au.team
IP address(es): 10.1.1.10
Domain name:    au.team
Realm name:     AU.TEAM

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=AU.TEAM
Subject base: O=AU.TEAM
Chaining:     self-signed

BIND DNS server will be configured to serve IPA domain with:
Forwarders:       10.1.1.1, 77.88.8.8
Forward policy:   only
Reverse zone(s):  1.1.10.in-addr.arpa.

Continue to configure the system with these values? [no]: yes
```

Результат по окончанию развёртывания:

```bash
Setup complete

Next steps:
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                  * 53: bind
                UDP Ports:
                  * 88, 464: kerberos
                  * 53: bind
                  * 123: ntp

        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
The ipa-server-install command was successful
```

Проверить статус подсистем:

```bash
[root@srv-hq ~]# ipactl status
Directory Service: RUNNING
krb5kdc Service: RUNNING
kadmin Service: RUNNING
named Service: RUNNING
httpd Service: RUNNING
ipa-custodia Service: RUNNING
pki-tomcatd Service: RUNNING
ipa-otpd Service: RUNNING
ipa-dnskeysyncd Service: RUNNING
ipa: INFO: The ipactl command was successful
[root@srv-hq ~]# 
```

При использование на других ВМ **SRV-HQ** в качестве DNS-сервера, возникает проблема с преобразованием доменных имён выходящих за рамки доменной зоны **au.team**:

```bash
[root@adm-hq ~]# host srv-hq.au.team 10.1.1.10
Using domain server:
Name: 10.1.1.10
Address: 10.1.1.10#53
Aliases: 

srv-hq.au.team has address 10.1.1.10
[root@adm-hq ~]# host ya.ru 10.1.1.10
Using domain server:
Name: 10.1.1.10
Address: 10.1.1.10#53
Aliases: 

Host ya.ru not found: 5(REFUSED)
```

Решилась данная проблема, выполнением следующих команд на **SRV-HQ**:

```bash
echo "allow-query { any; };" >> /etc/bind/ipa-options-ext.conf
ipactl restart
```

Результат преобразования имён:

```bash
[root@adm-hq ~]# host srv-hq.au.team 10.1.1.10
Using domain server:
Name: 10.1.1.10
Address: 10.1.1.10#53
Aliases: 

srv-hq.au.team has address 10.1.1.10
[root@adm-hq ~]# host ya.ru 10.1.1.10
Using domain server:
Name: 10.1.1.10
Address: 10.1.1.10#53
Aliases: 

ya.ru has address 77.88.55.242
ya.ru has address 77.88.44.242
ya.ru has address 5.255.255.242
ya.ru has IPv6 address 2a02:6b8::2:242
ya.ru mail is handled by 10 mx.yandex.ru.
[root@adm-hq ~]# 
```

## ADM-HQ:

Введём **FW-HQ** в домен FreeIPA.
Перейдите в Сервисы → DNS → Внешние DNS-серверы и добавьте IP-адрес устройства с установленной системой FreeIPA:

![FW-HQ_Setting_DNS](img/FW-HQ_Setting_DNS.png)

Результат и проверка:

![FW-HQ_Check_DNS](img/FW-HQ_Check_DNS.png)

```bash
[admin@fw-hq ~]# host srv-hq.au.team
srv-hq.au.team has address 10.1.1.10
[admin@fw-hq ~]# 
```

## SRV-HQ:

Для интеграции Ideco NGFW Novum с FreeIPA необходимо на IPA-сервере создать роли:
- **CIFS servers** - предоставляет NGFW Novum права для аутентификации пользователей по протоколу Kerberos, выступая в роли доверенной службы.
- **Organization units** - предоставляет NGFW Novum право на чтение структуры подразделений из каталога для корректного импорта пользователей и групп безопасности.

```bash
echo "P@ssw0rd" | kinit admin@AU.TEAM
```

- Для создания роли **CIFS servers**:

```bash
ipa role-add "CIFS server" --desc="Role for CIFS server"
```

- Для создания **Organization units**:

```bash
ipa role-add "Organization units" --desc="Role for Organization units"
```

## ADM-HQ:

Войдите в веб-интерфейс **Identity Manager** обратившись в браузере на https://srv-hq.au.team и авторизуйтесь с учетными данными администратора:

![FreeIPA_WebUI1](img/FreeIPA_WebUI1.png)

Перейдите в **IPA-сервер → Управление доступом на основе ролей** и убедитесь, что созданные роли появилсь в списке:

![HQ-FW_Check_Role](img/HQ-FW_Check_Role.png)

Войдите в каждую роль и добавьте объекты:
- **Пользователи** - выберите всех пользователей.
- **Группы пользователей** - выберите все группы.
- **Узлы** - выберите доменный узел.
- **Группы узлов** - выберите все группы.

![CIFS_Role_FreeIPA](img/CIFS_Role_FreeIPA.png)

![OU_Role_FreeIPA](img/OU_Role_FreeIPA.png)

Перезагрузите сервер FreeIPA для активации новых прав.

Для ввода FW-HQ в домен перейдите в **Пользователи → Внешние каталоги → FreeIPA**.Нажмите на кнопку **Добавить** и заполните поля:

![HQ-FW_Enter_Domain](img/HQ-FW_Enter_Domain.png)

Результат:

![HQ-FW_Check_Domain](img/HQ-FW_Check_Domain.png)

Также автоматически создалась и FORWARD-зона в DNS на FW-HQ, поэтому в качестве DNS можно использовать FW-HQ (хотя по умолчанию Ideco и так перехватывает все DNS запросы)

Стоит отключить "Перехват пользовательских DNS-запросов"!

Для возможности ввода в домен в Центр управления системой должен быть установлен пакет `task-auth-freeipa`:

```bash
apt-get update && apt-get install -y task-auth-freeipa
```

Ввод рабочей станции в домен FreeIPA в Центр управления системой:
1. Перейти в раздел **Пользователи** → **Аутентификация**.
2. В окне модуля **Аутентификация** выбрать пункт **Домен FreeIPA**.
3. Заполнить поля **Домен** и **Имя компьютера**.
4. Нажать кнопку **Применить**.
5. В открывшемся окне ввести учётные данные пользователя, с правами на регистрацию машин, и нажать кнопку **ОК**.
6. При успешном подключении к домену отобразится соответствующая информация.

![ADM-HQ_Enter_Domain](img/ADM-HQ_Enter_Domain.png)

После необходимо выполнить перезагрузку ADM-HQ, затем перейти в веб-интерфейс **Identity Manager** обратившись в браузере на https://srv-hq.au.team, и проверим узлы введённые в домен:

![Check_hosts_in_Domain](img/Check_hosts_in_Domain.png)

Устанавливаем Terraform:
- из-под root

```bash
wget https://hashicorp-releases.yandexcloud.net/terraform/1.14.5/terraform_1.14.5_linux_amd64.zip
```

```bash
unzip  terraform_1.14.5_linux_amd64.zip -d /usr/local/bin/
```

Настраиваем Terraform:
- из-под user

```bash
cat <<EOF > ~/.terraformrc
provider_installation {
    network_mirror {
        url = "https://terraform-mirror.mcs.mail.ru"
        include = ["registry.terraform.io/*/*"]
    }
    direct {
        exclude = ["registry.terraform.io/*/*"]
    }
}
EOF
```

```bash
mkdir /home/user/terraform
cd /home/user/terraform
```

```bash
cat <<EOF > terraform.tf
terraform {
  required_providers {
    freeipa = {
      source  = "camptocamp/freeipa"
      version = "1.0.0"
    }
  }
}
EOF
```

```bash
cat <<EOF > providers.tf
provider "freeipa" {
  host     = var.freeipa_host
  username = var.freeipa_username
  password = var.freeipa_username_password
  insecure = true
}
EOF
```

```bash
cat <<EOF > variable.tf
variable "freeipa_host" {
  type        = string
  description = "Access to the FreeIPA host"
}

variable "freeipa_username" {
  type        = string
  description = "Access to the FreeIPA host username"
}

variable "freeipa_username_password" {
  type        = string
  description = "Access to the FreeIPA host username password"
  sensitive   = true
}
EOF
```

```bash
cat <<EOF > terraform.tfvars
freeipa_host              = "srv-hq.au.team"
freeipa_username          = "admin"
freeipa_username_password = "P@ssw0rd"
EOF
```

Инициализируем директорию для работы с Terraform и указанным провайдером:

```bash
[user@adm-hq terraform]$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding camptocamp/freeipa versions matching "1.0.0"...
- Installing camptocamp/freeipa v1.0.0...
- Installed camptocamp/freeipa v1.0.0 (unauthenticated)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
[user@adm-hq terraform]$ 
```

Реализуем необходимый функционал:

```bash
cat <<EOF >> variable.tf

variable "reverse_zones" {
  description = "List of reverse viewing zones"
  type        = list(string)
  default = [
    "2.1.10.in-addr.arpa.",
    "0.2.10.in-addr.arpa.",
    "1.2.10.in-addr.arpa.",
    "2.2.10.in-addr.arpa.",
    "16.172.in-addr.arpa."
  ]
}

variable "dns_records" {
  description = "List of DNS records (A and corresponding PTR)"
  type = list(object({
    hostname            = string
    ip_address          = string
    forward_zone        = string
    reverse_zone        = optional(string)
    reverse_zone_record = optional(string)
  }))
  default = [
    {
      hostname            = "fw-hq"
      ip_address          = "10.1.1.1"
      forward_zone        = "au.team."
      reverse_zone        = "1.1.10.in-addr.arpa."
      reverse_zone_record = "1"
    },
    {
      hostname            = "adm-hq"
      ip_address          = "10.1.1.46"
      forward_zone        = "au.team."
      reverse_zone        = "1.1.10.in-addr.arpa."
      reverse_zone_record = "46"
    },
    {
      hostname            = "rtr-br"
      ip_address          = "10.2.0.1"
      forward_zone        = "au.team."
      reverse_zone        = "0.2.10.in-addr.arpa."
      reverse_zone_record = "1"
    },
    {
      hostname            = "fw-br"
      ip_address          = "10.2.0.2"
      forward_zone        = "au.team."
      reverse_zone        = "0.2.10.in-addr.arpa."
      reverse_zone_record = "2"
    },
    {
      hostname            = "srv-br"
      ip_address          = "10.2.1.10"
      forward_zone        = "au.team."
      reverse_zone        = "1.2.10.in-addr.arpa."
      reverse_zone_record = "10"
    },
    {
      hostname            = "rtr-cod"
      ip_address          = "172.16.1.254"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "254.1"
    },
    {
      hostname            = "sw-cod"
      ip_address          = "172.16.1.0"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "0.1"
    },
    {
      hostname            = "ha1-cod"
      ip_address          = "172.16.0.1"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "1.0"
    },
    {
      hostname            = "ha2-cod"
      ip_address          = "172.16.0.2"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "2.0"
    },
    {
      hostname            = "srv1-cod"
      ip_address          = "172.16.1.1"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "1.1"
    },
    {
      hostname            = "srv2-cod"
      ip_address          = "172.16.1.2"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "2.1"
    },
    {
      hostname            = "srv3-cod"
      ip_address          = "172.16.1.3"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "3.1"
    }
  ]
}
EOF
```

```bash
cat <<EOF > dns.tf
resource "freeipa_dns_zone" "reverse" {
  for_each  = toset(var.reverse_zones)
  zone_name = each.value
}

resource "freeipa_dns_record" "a" {
  for_each        = { for r in var.dns_records : r.hostname => r }
  dnszoneidnsname = each.value.forward_zone
  idnsname        = each.value.hostname
  records         = [each.value.ip_address]
  type            = "A"
}

resource "freeipa_dns_record" "ptr" {
  for_each        = { for r in var.dns_records : r.hostname => r }
  dnszoneidnsname = each.value.reverse_zone
  idnsname        = each.value.reverse_zone_record
  records         = ["${each.value.hostname}.${each.value.forward_zone}"]
  type            = "PTR"

  depends_on = [freeipa_dns_zone.reverse]
}
EOF
```

Запуск:

```bash
terraform apply -auto-approve
```

Проверяем соответствующие записи:

```bash
[root@srv-hq ~]# host fw-hq
fw-hq.au.team has address 10.1.1.1
[root@srv-hq ~]# host 10.1.1.1
1.1.1.10.in-addr.arpa domain name pointer fw-hq.au.team.
[root@srv-hq ~]# host adm-hq
adm-hq.au.team has address 10.1.1.46
[root@srv-hq ~]# host 10.1.1.46
46.1.1.10.in-addr.arpa domain name pointer adm-hq.au.team.
[root@srv-hq ~]# host rtr-br
rtr-br.au.team has address 10.2.0.1
[root@srv-hq ~]# host 10.2.0.1
1.0.2.10.in-addr.arpa domain name pointer rtr-br.au.team.
[root@srv-hq ~]# host fw-br
fw-br.au.team has address 10.2.0.2
[root@srv-hq ~]# host 10.2.0.2
2.0.2.10.in-addr.arpa domain name pointer fw-br.au.team.
[root@srv-hq ~]# host srv-br
srv-br.au.team has address 10.2.1.10
[root@srv-hq ~]# host 10.2.1.10
10.1.2.10.in-addr.arpa domain name pointer srv-br.au.team.
[root@srv-hq ~]# host rtr-cod
rtr-cod.au.team has address 172.16.1.254
[root@srv-hq ~]# host 172.16.1.254
254.1.16.172.in-addr.arpa domain name pointer rtr-cod.au.team.
[root@srv-hq ~]# host sw-cod
sw-cod.au.team has address 172.16.1.0
[root@srv-hq ~]# host 172.16.1.0
0.1.16.172.in-addr.arpa domain name pointer sw-cod.au.team.
[root@srv-hq ~]# host ha1-cod
ha1-cod.au.team has address 172.16.0.1
[root@srv-hq ~]# host 172.16.0.1
1.0.16.172.in-addr.arpa domain name pointer ha1-cod.au.team.
[root@srv-hq ~]# host ha2-cod
ha2-cod.au.team has address 172.16.0.2
[root@srv-hq ~]# host 172.16.0.2
2.0.16.172.in-addr.arpa domain name pointer ha2-cod.au.team.
[root@srv-hq ~]# host srv1-cod
srv1-cod.au.team has address 172.16.1.1
[root@srv-hq ~]# host 172.16.1.1
1.1.16.172.in-addr.arpa domain name pointer srv1-cod.au.team.
[root@srv-hq ~]# host srv2-cod
srv2-cod.au.team has address 172.16.1.2
[root@srv-hq ~]# host 172.16.1.2
2.1.16.172.in-addr.arpa domain name pointer srv2-cod.au.team.
[root@srv-hq ~]# host srv3-cod
srv3-cod.au.team has address 172.16.1.3
[root@srv-hq ~]# host 172.16.1.3
3.1.16.172.in-addr.arpa domain name pointer srv3-cod.au.team.
[root@srv-hq ~]# 
```

## SRV-HQ:

Создадим несколько тестовых групп и пользователей в домене:

```bash
echo "P@ssw0rd" | kinit admin
```

```bash
ipa group-add hq
ipa group-add br
ipa group-add cod
``` 

```bash
for i in {1..5}; do
echo "P@ssw0rd" | ipa user-add hq.user$i --first=hq --last=user$i --password
echo "P@ssw0rd" | ipa user-add br.user$i --first=br --last=user$i --password
echo "P@ssw0rd" | ipa user-add cod.user$i --first=cod --last=user$i --password
done
```

```bash
for i in {1..5}; do
ipa group-add-member hq --users=hq.user$i
ipa group-add-member br --users=br.user$i
ipa group-add-member cod --users=cod.user$i
done
```

## ADM-HQ: 

Проверить наличие созданных групп и пользователей:

![Check_FreeIPA_Groups](img/Check_FreeIPA_Groups.png)

![Check_FreeIPA_Users](img/Check_FreeIPA_Users.png)

Для импорта пользователей из домена FreeIPA на FW-HQ, создадим следующую структуру групп на уровне Ideco:

![FW-HQ_Create_Groups](img/FW-HQ_Create_Groups.png)

В каждую группу импортируем пользователей из одноимённых групп безопасности домена:

![FW-HQ_Import_Users_FreeIPA](img/FW-HQ_Import_Users_FreeIPA.png)

**Удаляем** учётную запись **network**, а также авторизацию по подсети, которая изначально создавалась как временное решение.

Создаём авторизацию для SRV-HQ из-под пользователя hq.user5 по IP:

![FW-HQ_Authorized_SRV-HQ1](img/FW-HQ_Authorized_SRV-HQ1.png)

Результат:

![FW-HQ_Authorized_SRV-HQ2.png](img/FW-HQ_Authorized_SRV-HQ2.png)

![FW-HQ_Authorized_SRV-HQ3](img/FW-HQ_Authorized_SRV-HQ3.png)

```bash
[root@srv-hq ~]# ping -c3 ya.ru
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=19.0 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=20.0 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=3 ttl=53 time=19.4 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 19.037/19.471/19.994/0.395 ms
[root@srv-hq ~]# 
```

## SRV-HQ: 

Настраиваем Kea DHCP

Установим пакет `kea-dhcp4`:

```bash
apt-get install -y kea-dhcp4
```

Создадим конфигурационный файл для сети клиента **CLI-HQ**:

```bash
cat <<EOF > /etc/kea/kea-dhcp4.conf
{
  "Dhcp4": {
    "valid-lifetime": 86400,
    "renew-timer": 43200,
    "rebind-timer": 75600,

    "interfaces-config": {
      "interfaces": [
        "ens19"
      ]
    },
    
    "control-socket": {
      "socket-type": "unix",
      "socket-name": "/run/kea/kea4-ctrl-socket"
    },
    
    "lease-database": {
      "type": "memfile",
      "name": "/var/lib/kea/kea-leases4.csv", 
      "lfc-interval": 600
    },
    
    "subnet4": [
      {
        "id": 150,
        "subnet": "10.1.2.0/24",
        "pools": [
          {
            "pool": "10.1.2.128 - 10.1.2.254"
          }
        ],
        "option-data": [
          {
            "name": "routers",
            "data": "10.1.2.1"
          },
          {
            "name": "domain-name-servers",
            "data": "10.1.1.10"
          },
          {
            "name": "domain-name",
            "data": "au.team"
          },
          {
            "name": "domain-search",
            "data": "au.team"
          }
        ]
      }
    ]
  }
}
EOF
```

```bash
systemctl enable --now kea-dhcp4.service
```

## ADM-HQ: 

На FW-HQ необходимо организовать DHCP-Relay:

![HQ-FW_Relay_Add](img/HQ-FW_Relay_Add.png)

![HQ-FW_Relay_Enable](img/HQ-FW_Relay_Enable.png)

Так же включим возможность веб-аутентификации по логину и паролю для пользователей группы hq:

![FW-HQ_Web-Auth](img/FW-HQ_Web-Auth.png)

## CLI-HQ:

Выполняем коммутацию в соответствие с L2:

![CLI-HQ_Switching](img/CLI-HQ_Switching.png)

Проверяем получение сетевых параметров:
- задаём также имя на устройство

```bash
hostnamectl set-hostname cli-hq.au.team; exec bash
```

```bash
[root@cli-hq ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             10.1.2.128/24 
[root@cli-hq ~]# ip -c r
default via 10.1.2.1 dev ens19 proto dhcp src 10.1.2.128 metric 100 
10.1.2.0/24 dev ens19 proto kernel scope link src 10.1.2.128 metric 100 
[root@cli-hq ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@cli-hq ~]# host ya.ru
ya.ru has address 5.255.255.242
ya.ru has address 77.88.44.242
ya.ru has address 77.88.55.242
ya.ru has IPv6 address 2a02:6b8::2:242
ya.ru mail is handled by 10 mx.yandex.ru.
[root@cli-hq ~]# 
```

Открываем браузер, обращаемся на ya.ru, проходим веб-аутентификацию из-под пользователя hq.user1@au.team с паролем P@ssw0rd и для возможности ввода в домен в Центр управления системой должен быть установлен пакет `task-auth-freeipa`:

```bash
apt-get update && apt-get install -y task-auth-freeipa
```

Ввод рабочей станции в домен FreeIPA в Центр управления системой:
1. Перейти в раздел **Пользователи** → **Аутентификация**.
2. В окне модуля **Аутентификация** выбрать пункт **Домен FreeIPA**.
3. Заполнить поля **Домен** и **Имя компьютера**.
4. Нажать кнопку **Применить**.
5. В открывшемся окне ввести учётные данные пользователя, с правами на регистрацию машин, и нажать кнопку **ОК**.
6. При успешном подключении к домену отобразится соответствующая информация.

![CLI-HQ_Enter_in_Domain](img/CLI-HQ_Enter_in_Domain.png)

Также стоит перезагрузить CLI-HQ. И добавить корневой сертификат FW-HQ аналогично ADM-HQ.

Также при установке Ideco Client работает авторизация:

![CLI-HQ_Ideco_Client1](img/CLI-HQ_Ideco_Client1.png)

![CLI-HQ_Ideco_Client2](img/CLI-HQ_Ideco_Client2.png)

![CLI-HQ_Ideco_Client3](img/CLI-HQ_Ideco_Client3.png)

## RTR-BR

Базовая настройка:
- имя
- адресация в соответствие с L3

```text
enable
configure terminal
hostname rtr-br
ip domain-name au.team

username net_admin
password P@ssw0rd
role admin
exit

interface int0
description "Connect-to-ISP"
ip address 84.212.78.78/27
exit

port te0
service-instance te0/int0
encapsulation untagged 
connect ip interface int0 
exit
exit

interface int1
description "Connect-to-FW-BR"
ip address 10.2.0.1/30
exit

port te1
service-instance te1/int1
encapsulation untagged 
connect ip interface int1
exit
exit

write memory
```

Проверить:

```text
rtr-br(config)#do show interface description 
 Interface        Status           Protocol         Description
 ---------------------------------------------------------------
 int0             up               up               "Connect-to-ISP"
 int1             up               up               "Connect-to-FW-BR"
rtr-br(config)#do show ip int brief 
 Interface        IP-Address          Status                 VRF
 ----------------------------------------------------------------
 int0             84.212.78.78/27     up                     default
 int1             10.2.0.1/30         up                     default
rtr-br(config)#do ping 84.212.78.94
PING 84.212.78.94 (84.212.78.94) 56(84) bytes of data.
64 bytes from 84.212.78.94: icmp_seq=1 ttl=64 time=28.2 ms
64 bytes from 84.212.78.94: icmp_seq=2 ttl=64 time=18.9 ms
64 bytes from 84.212.78.94: icmp_seq=3 ttl=64 time=26.1 ms

--- 84.212.78.94 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 18.868/24.382/28.224/3.998 ms
rtr-br(config)#
```

Создаём интерфейс `loopback.0` и назначаем на него IP-адрес:

```text
interface loopback.0
ip address 192.168.255.2/32
no shutdown 
exit
```

Проверить:

```text
rtr-br(config)#do show ip interface brief
 Interface        IP-Address          Status                 VRF
 ----------------------------------------------------------------
 int0             84.212.78.78/27     up                     default
 int1             10.2.0.1/30         up                     default
 loopback.0       192.168.255.2/32    up                     default
rtr-br(config)#
```

Минимальная конфигурация IS-IS:

```text
router isis
net 49.0001.1921.6825.5002.00
is-type level-2-only
metric-style wide
passive-interface loopback.0 
exit

interface int0 
ip router isis
isis circuit-type level-2-only
isis network point-to-point
exit

interface loopback.0
ip router isis
exit
```

Проверить:

```text
rtr-br(config)#do show ip route isis
IP Route Table for VRF "default"
i L2    192.168.255.1/32 [115/20] via 84.212.78.94, int0, 00:00:23

Gateway of last resort is not set
rtr-br(config)#do ping 192.168.255.1
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.1: icmp_seq=1 ttl=64 time=44.9 ms
64 bytes from 192.168.255.1: icmp_seq=2 ttl=64 time=19.9 ms
64 bytes from 192.168.255.1: icmp_seq=3 ttl=64 time=27.3 ms

--- 192.168.255.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 19.925/30.697/44.887/10.473 ms
rtr-br(config)#
```

Минимальная конфигурация BGP:

```text
router bgp 64499
bgp router-id 192.168.255.2
bgp log-neighbor-changes
neighbor 192.168.255.1 remote-as 64499
neighbor 192.168.255.1 update-source loopback.0
neighbor 192.168.255.1 description iBGP-to-ISP
address-family ipv4 unicast
neighbor 192.168.255.1 activate
neighbor 192.168.255.1 next-hop-self
exit-address-family
exit

write memory
```

Проверить:

```text
rtr-hq#show ip bgp summary 
BGP router identifier 192.168.255.2, local AS number 64499
BGP table version is 2
1 BGP AS-PATH entries
0 BGP community entries

Neighbor        V    AS     MsgRcv    MsgSen    TblVer  InQ   OutQ   Up/Down   State/PfxRcd
-------------------------------------------------------------------------------------------
192.168.255.1   4    64499  10        8         2       0     0      00:02:37     2

Total number of neighbors 1

Total number of Established sessions 1
rtr-hq#
```

```text
rtr-br#show ip route
Codes: C - connected, S - static, R - RIP, B - BGP
       O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, L1 - IS-IS level-1, L2 - IS-IS level-2, ia - IS-IS inter area
       * - candidate default

IP Route Table for VRF "default"
Gateway of last resort is 192.168.255.1 to network 0.0.0.0

B*      0.0.0.0/0 [200/0] via 192.168.255.1 (recursive  via 84.212.78.94), 00:00:25
C       10.2.0.0/30 is directly connected, int1
C       84.212.78.64/27 is directly connected, int0
B       100.64.0.0/16 [200/0] via 192.168.255.1 (recursive  via 84.212.78.94), 00:00:25
i L2    192.168.255.1/32 [115/20] via 84.212.78.94, int0, 00:02:02
C       192.168.255.2/32 is directly connected, loopback.0
rtr-br#ping 77.88.8.8
PING 77.88.8.8 (77.88.8.8) 56(84) bytes of data.
64 bytes from 77.88.8.8: icmp_seq=1 ttl=54 time=76.7 ms
64 bytes from 77.88.8.8: icmp_seq=2 ttl=54 time=43.2 ms
64 bytes from 77.88.8.8: icmp_seq=3 ttl=54 time=49.2 ms

--- 77.88.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 43.241/56.383/76.733/14.592 ms
rtr-br#
```

Минимальная конфигурация OSPF:

```text
router ospf 2
area 1 stub
passive-interface default
no passive-interface int1 
network 10.2.0.0/30 area 0
default-information originate
exit

write memory
```

## FW-BR

Задаём имя:

```shell
localhost> enable 
Type the administrator password: 
localhost# 
```

```text
machine set hostname fw-br.au.team
```

Для организации обработки трафика из нескольких VLAN выполните следующие действия:
- Завершите работу управляющей службы
- Измените класс интерфейса, к которому подключен коммутатор

```shell
fw-br.au.team# iplir stop
Shutting down IpLir
..
fw-br.au.team# inet ifconfig eth1 class trunk
All IP addresses and their aliases on this interface will be deleted.
Continue?[Yes,No]: Yes
Interface eth1 has lost DHCP configured information such as default gateway,
DNS and NTP servers.  This may affect network connectivity and local services
like DNS and NTP.  Please check their status manually.
eth1 set to trunk class.
fw-br.au.team# 
```

- Задайте номера виртуальных интерфейсов, которые будут соответствовать виртуальным сетям за коммутатором:
	- в соответствие с L2

```shell
fw-br.au.team# inet ifconfig eth1 vlan add 10
The new vlan interface eth1.10 has been created.
Use command "iplir config" and add this interface to configuration in order to use it.
fw-br.au.team# inet ifconfig eth1 vlan add 20
The new vlan interface eth1.20 has been created.
Use command "iplir config" and add this interface to configuration in order to use it.
fw-br.au.team# 
```

- Присвойте IP-адреса виртуальным интерфейсам:
	- в соответствие с L3

```shell
inet ifconfig eth1.10 address 10.2.1.14 netmask 255.255.255.240
inet ifconfig eth1.20 address 10.2.2.1 netmask 255.255.255.128
```

- Откройте для редактирования конфигурационный файл `iplir.conf`:

```shell
iplir config
```

- В секции `[adapter]` с описанием интерфейса, к которому подключен коммутатор, присвойте параметру `allowtraffic` значение `off`:

```text
[adapter]
name= eth1
allowtraffic= off
type= internal
```

- Добавьте секции `[adapter]`, описывающие созданные виртуальные интерфейсы:

```text
[adapter]
name= eth1.10
allowtraffic= on
type= internal

[adapter]
name= eth1.20
allowtraffic= on
type= internal
```

- Включите физический интерфейс, к которому подключен коммутатор
	- При этом автоматически будут включены созданные виртуальные интерфейсы
- Запустите управляющую службу

```shell
inet ifconfig eth1 up
iplir start
```

Проверить:

```shell
fw-br.au.team# inet show vlan
VLAN intefaces
Id      | Name          | IP            | Parent| Comment
10      | eth1.10       | 10.2.1.14     | eth1  | 
20      | eth1.20       | 10.2.2.1      | eth1  | 
fw-br.au.team# 
```

Назначаем IP на интерфейс в сторону RTR-BR:

```shell
inet ifconfig eth0 address 10.2.0.2 netmask 255.255.255.252
```

Проверить:

```shell
fw-br.au.team# inet show interface eth0
----------
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.2.0.2  netmask 255.255.255.252  broadcast 10.2.0.3
        ether bc:24:11:bb:40:e4  txqueuelen 1000  (Ethernet)
        RX packets 73  bytes 5686 (5.5 KiB)
        RX errors 0  dropped 1  overruns 0  frame 0
        TX packets 72  bytes 23572 (23.0 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

          Configured by DHCP: no
          Class: access

          Link detected: yes

fw-br.au.team# 
```

Настраиваем OSPF:

```shell
inet ospf mode on
```

```shell
inet ospf network add 10.2.0.0 netmask 255.255.255.252 area 0
```

```shell
inet ospf network add 10.2.1.0 netmask 255.255.255.240 area 0
inet ospf network add 10.2.2.0 netmask 255.255.255.128 area 0
```

Добавляем правила в firewall:

```shell
firewall forward add 1 src @any dst @any pass
firewall local add 1 src @any dst @any pass
```

Проверить:

```shell
fw-br.au.team# inet show ospf neighbour 

    Neighbor ID Pri State           Dead Time Address         Interface            RXmtL RqstL DBsmL
192.168.255.2     1 Full/DR           33.332s 10.2.0.1        eth0:10.2.0.2            0     0     0
fw-br.au.team# inet show routing 
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, A - Babel, D - DHCP/PPP,
       > - selected route, * - FIB route


Routing table MAIN (254):
O>* 0.0.0.0/0 [110/10] via 10.2.0.1, eth0, 00:00:43
O   10.2.0.0/30 [110/10] is directly connected, eth0, 00:03:40
C>* 10.2.0.0/30 is directly connected, eth0
O   10.2.1.0/28 [110/10] is directly connected, eth1.10, 00:02:38
C>* 10.2.1.0/28 is directly connected, eth1.10
O   10.2.2.0/25 [110/10] is directly connected, eth1.20, 00:02:37
C>* 10.2.2.0/25 is directly connected, eth1.20
C>* 127.0.0.0/8 is directly connected, lo
fw-br.au.team# 
```

### ADM-HQ:

Создаём туннельный интерфейс `tunnel.1` в сторону RTR-BR с IP-адресом `10.0.1.1/30`:

![FW-HQ_Create_tunnel1](img/FW-HQ_Create_tunnel1.png)

Результат:

![FW-HQ_Check_tunnel1](img/FW-HQ_Check_tunnel1.png)

Аналогично и для tunnel.2, результат:

![FW-HQ_Check_GRE](img/FW-HQ_Check_GRE.png)

### RTR-BR:

Создаём туннельный интерфейс `tunnel.1` в сторону FW-HQ с IP-адресом `10.0.1.2/30`:

```text
interface tunnel.1
description "GRE-to-FW-HQ"
ip address 10.0.1.2/30
ip tunnel 84.212.78.78 63.27.18.18 mode gre
exit
```

Проверить:

```text
rtr-br(config)#do show interface tunnel.1 
 Interface tunnel.1 is up
  Description: "GRE-to-FW-HQ"
  Snmp index: 8
  Ethernet address: (port not configured)
  MTU: 1476
  Tunnel source: 84.212.78.78
  Tunnel destination: 63.27.18.18
  Tunnel mode: GRE
  Tunnel keepalive: disabled
  NAT: no
  ARP Proxy: disable
  ICMP redirects on, unreachables on 
  IP URPF is disabled
  Label switching is disabled
  <UP,BROADCAST,RUNNING,NOARP,MULTICAST>
  inet 10.0.1.2/30 broadcast 10.0.1.3/30
  total input packets 2, bytes 168
  total output packets 2, bytes 168
rtr-br(config)#do ping 10.0.1.1
PING 10.0.1.1 (10.0.1.1) 56(84) bytes of data.
64 bytes from 10.0.1.1: icmp_seq=1 ttl=64 time=63.5 ms
64 bytes from 10.0.1.1: icmp_seq=2 ttl=64 time=22.4 ms
64 bytes from 10.0.1.1: icmp_seq=3 ttl=64 time=21.0 ms

--- 10.0.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 20.984/35.627/63.543/19.747 ms
rtr-br(config)#
```

Добавлены статические маршруты через туннель:

```text
ip route 10.1.1.0/27 10.0.1.1
ip route 10.1.1.32/28 10.0.1.1
ip route 10.1.2.0/24 10.0.1.1
```

Проверить:

```text
rtr-br#show ip route static 
IP Route Table for VRF "default"
S       10.1.1.0/27 [1/0] via 10.0.1.1, tunnel.1
S       10.1.1.32/28 [1/0] via 10.0.1.1, tunnel.1
S       10.1.2.0/24 [1/0] via 10.0.1.1, tunnel.1

Gateway of last resort is not set
rtr-br#
```

## ADM-HQ:

Добавлены статические маршруты на FW-HQ:

![HQ-FW_Static_Routers](img/HQ-FW_Static_Routers.png)

## ADM-HQ:

Проверяем доступ к WebUI FW-BR обратившись по http://10.2.0.2:8080:

![FW-BR_WebGUI](img/FW-BR_WebGUI.png)

![FW-BR_WebGUI_Admin](img/FW-BR_WebGUI_Admin.png)

DHCP-сервер:

![BR-FW_DHCP](img/BR-FW_DHCP.png)

## CLI-HQ:

Выполняем коммутацию в соответствие с L2:

![CLI-HQ_Switching](img/CLI-BR_Switching.png)

Проверяем получение сетевых параметров:
- задаём также имя на устройство

```bash
hostnamectl set-hostname cli-br.au.team; exec bash
```

```bash
[root@cli-br ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             10.2.2.2/25 
[root@cli-br ~]# ip -c r
default via 10.2.2.1 dev ens19 proto dhcp src 10.2.2.2 metric 100 
10.2.2.0/25 dev ens19 proto kernel scope link src 10.2.2.2 metric 100 
[root@cli-br ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@cli-br ~]# 
```

## SRV-BR:

База:
- коммутация
- имя
- адресация

```bash
hostnamectl set-hostname srv-br.au.team; exec bash
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "10.2.1.10/28" > /etc/net/ifaces/ens19/ipv4address
echo "default via 10.2.1.14" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@srv-br ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             10.2.1.10/28 
[root@srv-br ~]# ip -c r
default via 10.2.1.14 dev ens19 
10.2.1.0/28 dev ens19 proto kernel scope link src 10.2.1.10 
[root@srv-br ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@srv-br ~]# ping -c3 10.2.1.14
PING 10.2.1.14 (10.2.1.14) 56(84) bytes of data.
64 bytes from 10.2.1.14: icmp_seq=1 ttl=64 time=1.22 ms
64 bytes from 10.2.1.14: icmp_seq=2 ttl=64 time=0.613 ms
64 bytes from 10.2.1.14: icmp_seq=3 ttl=64 time=0.913 ms

--- 10.2.1.14 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.613/0.915/1.220/0.247 ms
[root@srv-br ~]# 
```

## RTR-BR:

Настраиваем NAT:

```text
interface int0
ip nat outside 
exit

interface int1
ip nat inside 
exit

ip nat pool BR 10.2.0.1-10.2.2.126

ip nat source dynamic inside-to-outside pool BR overload interface int0
write memory
```

Проверить:

```bash
[root@srv-br ~]# ping -c3 77.88.8.8
PING 77.88.8.8 (77.88.8.8) 56(84) bytes of data.
64 bytes from 77.88.8.8: icmp_seq=1 ttl=52 time=45.2 ms
64 bytes from 77.88.8.8: icmp_seq=2 ttl=52 time=44.7 ms
64 bytes from 77.88.8.8: icmp_seq=3 ttl=52 time=45.8 ms

--- 77.88.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 44.741/45.241/45.803/0.435 ms
[root@srv-br ~]# 
```

```bash
[root@cli-br ~]# ping -c3 77.88.8.8
PING 77.88.8.8 (77.88.8.8) 56(84) bytes of data.
64 bytes from 77.88.8.8: icmp_seq=1 ttl=52 time=83.9 ms
64 bytes from 77.88.8.8: icmp_seq=2 ttl=52 time=46.4 ms
64 bytes from 77.88.8.8: icmp_seq=3 ttl=52 time=44.7 ms

--- 77.88.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 44.706/58.318/83.862/18.075 ms
[root@cli-br ~]#
```

## CLI-BR:

Для возможности ввода в домен в Центр управления системой должен быть установлен пакет `task-auth-freeipa`:

```bash
apt-get update && apt-get install -y task-auth-freeipa
```

Ввод рабочей станции в домен FreeIPA в Центр управления системой:
1. Перейти в раздел **Пользователи** → **Аутентификация**.
2. В окне модуля **Аутентификация** выбрать пункт **Домен FreeIPA**.
3. Заполнить поля **Домен** и **Имя компьютера**.
4. Нажать кнопку **Применить**.
5. В открывшемся окне ввести учётные данные пользователя, с правами на регистрацию машин, и нажать кнопку **ОК**.
6. При успешном подключении к домену отобразится соответствующая информация.

![CLI-BR_Enter_in_Domain](img/CLI-BR_Enter_in_Domain.png)

Стоит перезагрузить CLI-BR.

### RTR-COD:

Базовая настройка:
- имя
- адресация в соответствие с L3

```text
enable
configure terminal
hostname rtr-cod
ip domain-name au.team

username net_admin
password P@ssw0rd
role admin
exit

interface int0
description "Connect-to-ISP"
ip address 34.95.33.33/24
exit

port te0
service-instance te0/int0
encapsulation untagged 
connect ip interface int0 
exit
exit

interface int1
description "Connect-to-SW-COD"
ip address 172.16.1.254/23
exit

port te1
service-instance te1/int1
encapsulation untagged 
connect ip interface int1
exit
exit

write memory
```

Проверить:

```text
rtr-cod(config)#do show interface description 
 Interface        Status           Protocol         Description
 ---------------------------------------------------------------
 int0             up               up               "Connect-to-ISP"
 int1             up               up               "Connect-to-SW-COD"
rtr-cod(config)#do show ip int br
 Interface        IP-Address          Status                 VRF
 ----------------------------------------------------------------
 int0             34.95.33.33/24      up                     default
 int1             172.16.1.254/23     up                     default
rtr-cod(config)#do ping 34.95.33.254
PING 34.95.33.254 (34.95.33.254) 56(84) bytes of data.
64 bytes from 34.95.33.254: icmp_seq=1 ttl=64 time=30.6 ms
64 bytes from 34.95.33.254: icmp_seq=2 ttl=64 time=44.8 ms
64 bytes from 34.95.33.254: icmp_seq=3 ttl=64 time=19.2 ms

--- 34.95.33.254 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 19.171/31.497/44.756/10.465 ms
rtr-cod(config)#
```

Настройка BGP:

```text
router  bgp 64499
bgp router-id 34.95.33.33
neighbor 34.95.33.254 remote-as 64499
exit
write memory
```

Проверить:

```text
rtr-cod(config)#do show ip bgp summary 
BGP router identifier 34.95.33.33, local AS number 64499
BGP table version is 2
1 BGP AS-PATH entries
0 BGP community entries

Neighbor        V    AS     MsgRcv    MsgSen    TblVer  InQ   OutQ   Up/Down   State/PfxRcd
-------------------------------------------------------------------------------------------
34.95.33.254    4    64499  5         2         2       0     0      00:00:06     2

Total number of neighbors 1

Total number of Established sessions 1
rtr-cod(config)#do show ip route 
Codes: C - connected, S - static, R - RIP, B - BGP
       O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, L1 - IS-IS level-1, L2 - IS-IS level-2, ia - IS-IS inter area
       * - candidate default

IP Route Table for VRF "default"
Gateway of last resort is 34.95.33.254 to network 0.0.0.0

B*      0.0.0.0/0 [200/0] via 34.95.33.254, int0, 00:00:04
C       34.95.33.0/24 is directly connected, int0
B       100.64.0.0/16 [200/0] via 34.95.33.254, int0, 00:00:04
C       172.16.0.0/23 is directly connected, int1
rtr-cod(config)#
```

Настройка NAT:

```text
interface int0
ip nat outside 
exit

interface int1
ip nat inside 
exit

ip nat pool COD 172.16.0.1-172.16.1.254

ip nat source dynamic inside-to-outside pool COD overload interface int0
write memory
```

Настройка GRE-туннелей:

```text
interface tunnel.2
description "GRE-to-FW-HQ"
ip address 10.0.2.2/30
ip tunnel 34.95.33.33 63.27.18.18 mode gre
exit

interface tunnel.3
description "GRE-to-RTR-BR"
ip address 10.0.3.1/30
ip tunnel 34.95.33.33 84.212.78.78 mode gre
exit
```

Настройка OSPF:

```text
router ospf 1
passive-interface default
no passive-interface tunnel.3 
network 10.0.3.0/30 area 0
network 172.16.0.0/23 area 0
exit
```

Статическая маршрутизация:

```text
ip route 10.1.1.0/27 10.0.2.1
ip route 10.1.1.32/28 10.0.2.1
ip route 10.1.2.0/24 10.0.2.1

write memory
```

## RTR-BR:

GRE-туннель:

```text
interface tunnel.3
description "GRE-to-RTR-COD"
ip address 10.0.3.2/30
ip tunnel 84.212.78.78 34.95.33.33 mode gre
exit
```

OSPF:

```text
router ospf 1
no passive-interface tunnel.3 
network 10.0.3.0/30 area 0
exit

write memory
```

Проверить:

```text
rtr-br(config)#do show ip ospf neighbor 

Total number of full neighbors: 2
OSPF process 1 VRF(default):
Neighbor ID     Pri   State            Dead Time   Address         Interface           Instance ID
172.16.1.254      1   Full/DR          00:00:32    10.0.3.1        tunnel.3                0
10.2.2.1          1   Full/DR          00:00:36    10.2.0.2        int1                    0
rtr-br(config)#do show ip route ospf 
IP Route Table for VRF "default"
O       10.2.1.0/28 [110/11] via 10.2.0.2, int1, 00:00:13
O       10.2.2.0/25 [110/11] via 10.2.0.2, int1, 00:00:13
O       172.16.0.0/23 [110/2] via 10.0.3.1, tunnel.3, 00:00:55

Gateway of last resort is not set
rtr-br(config)#
```

## SW-COD:

Настройка имени:

```bash
hostnamectl set-hostname sw-cod.au.team; exec bash
```

Настройка пользователя:

```bash
useradd net_admin
```

```bash
passwd net_admin
```

```bash
usermod -aG wheel net_admin
echo "net_admin ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
```

Настройка временного IP для установки openvswitch:

```bash
ip addr add 172.16.1.0/23 dev ens19
ip route add 0.0.0.0/0 via 172.16.1.254
echo "nameserver 77.88.8.8" > /etc/resolv.conf
```

```bash
apt-get update && apt-get install -y openvswitch
```

```bash
systemctl enable --now openvswitch
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
reboot
```

Настраиваем коммутацию:

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
cp -r /etc/net/ifaces/ens{19,20}/
cp -r /etc/net/ifaces/ens{19,21}/
cp -r /etc/net/ifaces/ens{19,22}/
cp -r /etc/net/ifaces/ens19 /etc/net/ifaces/enp2s29
cp -r /etc/net/ifaces/ens19 /etc/net/ifaces/enp3s12
systemctl restart network
```

Проверить:

```bash
[root@sw-cod ~]# ip -c -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens19            UP             fe80::be24:11ff:fe0e:a1ee/64 
ens20            UP             fe80::be24:11ff:fe3a:b35a/64 
ens21            UP             fe80::be24:11ff:fed2:db1f/64 
ens22            UP             fe80::be24:11ff:fea0:588f/64 
enp2s29          UP             fe80::be24:11ff:fe51:5146/64 
enp3s12          UP             fe80::be24:11ff:fe4b:9976/64 
[root@sw-cod ~]# 
```

Создаём коммутатор:

```bash
ovs-vsctl add-br sw-cod
```

Добавляем интерфейсы в коммутатор:

```bash
ovs-vsctl add-port sw-cod ens19
ovs-vsctl add-port sw-cod ens20
ovs-vsctl add-port sw-cod ens21
ovs-vsctl add-port sw-cod ens22
ovs-vsctl add-port sw-cod enp2s29
ovs-vsctl add-port sw-cod enp3s12
```

Создаём порт управления для назначения IP-адреса:

```bash
mkdir /etc/net/ifaces/mgmt
cat <<EOF > /etc/net/ifaces/mgmt/options
TYPE=ovsport
BOOTPROTO=static
CONFIG_IPv4=yes
BRIDGE=sw-cod
EOF
echo "172.16.1.0/23" > /etc/net/ifaces/mgmt/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/mgmt/ipv4route
echo "search au.team" > /etc/net/ifaces/mgmt/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/mgmt/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@sw-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
mgmt             UNKNOWN        172.16.1.0/23 
[root@sw-cod ~]# ip -c r
default via 172.16.1.254 dev mgmt 
172.16.0.0/23 dev mgmt proto kernel scope link src 172.16.1.0 
[root@sw-cod ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@sw-cod ~]# ping -c3 10.1.1.10
PING 10.1.1.10 (10.1.1.10) 56(84) bytes of data.
64 bytes from 10.1.1.10: icmp_seq=1 ttl=62 time=27.7 ms
64 bytes from 10.1.1.10: icmp_seq=2 ttl=62 time=26.9 ms
64 bytes from 10.1.1.10: icmp_seq=3 ttl=62 time=28.4 ms

--- 10.1.1.10 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 26.896/27.672/28.422/0.623 ms
[root@sw-cod ~]# 
```

```bash
[root@sw-cod ~]# ovs-vsctl show
bbdcec69-22e3-4d0e-bbd8-2f8beee7e3cd
    Bridge sw-cod
        Port ens21
            Interface ens21
        Port enp3s12
            Interface enp3s12
        Port ens20
            Interface ens20
        Port ens19
            Interface ens19
        Port sw-cod
            Interface sw-cod
                type: internal
        Port mgmt
            Interface mgmt
                type: internal
        Port enp2s29
            Interface enp2s29
        Port ens22
            Interface ens22
    ovs_version: "3.3.2"
[root@sw-cod ~]# 
```

## HA1-COD:

База:
- имя
- адресация

```bash
hostnamectl set-hostname ha1-cod.au.team; exec bash
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "172.16.0.1/23" > /etc/net/ifaces/ens19/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@ha1-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.16.0.1/23 
[root@ha1-cod ~]# ip -c r
default via 172.16.1.254 dev ens19 
172.16.0.0/23 dev ens19 proto kernel scope link src 172.16.0.1 
[root@ha1-cod ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@ha1-cod ~]# ping -c3 ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=54 time=29.6 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=54 time=30.0 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=54 time=30.3 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 29.606/29.962/30.263/0.271 ms
[root@ha1-cod ~]# 
```

## HA2-COD:

База:
- имя
- адресация

```bash
hostnamectl set-hostname ha2-cod.au.team; exec bash
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "172.16.0.2/23" > /etc/net/ifaces/ens19/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@ha2-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.16.0.2/23 
[root@ha2-cod ~]# ip -c r
default via 172.16.1.254 dev ens19 
172.16.0.0/23 dev ens19 proto kernel scope link src 172.16.0.2 
[root@ha2-cod ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@ha2-cod ~]# ping -c3 ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=54 time=30.5 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=54 time=95.2 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=54 time=31.2 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 30.463/52.284/95.154/30.314 ms
[root@ha2-cod ~]# 
```

## SRV1-COD:

База:
- имя
- адресация

```bash
hostnamectl set-hostname srv1-cod.au.team; exec bash
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "172.16.1.1/23" > /etc/net/ifaces/ens19/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@srv1-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.16.1.1/23 
[root@srv1-cod ~]# ip -c r
default via 172.16.1.254 dev ens19 
172.16.0.0/23 dev ens19 proto kernel scope link src 172.16.1.1 
[root@srv1-cod ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@srv1-cod ~]# ping -c3 ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=54 time=75.2 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=54 time=73.4 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=54 time=71.4 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 71.353/73.337/75.235/1.586 ms
[root@srv1-cod ~]# 
```

## SRV2-COD:

База:
- имя
- адресация

```bash
hostnamectl set-hostname srv2-cod.au.team; exec bash
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "172.16.1.2/23" > /etc/net/ifaces/ens19/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@srv2-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.16.1.2/23 
[root@srv2-cod ~]# ip -c r
default via 172.16.1.254 dev ens19 
172.16.0.0/23 dev ens19 proto kernel scope link src 172.16.1.2 
[root@srv2-cod ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@srv2-cod ~]# ping -c3 ya.ru
PING ya.ru (77.88.55.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.55.242): icmp_seq=1 ttl=54 time=70.1 ms
64 bytes from ya.ru (77.88.55.242): icmp_seq=2 ttl=54 time=68.9 ms
64 bytes from ya.ru (77.88.55.242): icmp_seq=3 ttl=54 time=67.3 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 67.276/68.776/70.148/1.176 ms
[root@srv2-cod ~]# 
```

## SRV3-COD:

База:
- имя
- адресация

```bash
hostnamectl set-hostname srv3-cod.au.team; exec bash
```

```bash
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "172.16.1.3/23" > /etc/net/ifaces/ens19/ipv4address
echo "default via 172.16.1.254" > /etc/net/ifaces/ens19/ipv4route
echo "search au.team" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

Проверить:

```bash
[root@srv3-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.16.1.3/23 
[root@srv3-cod ~]# ip -c r
default via 172.16.1.254 dev ens19 
172.16.0.0/23 dev ens19 proto kernel scope link src 172.16.1.3 
[root@srv3-cod ~]# cat /etc/resolv.conf
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
search au.team
nameserver 10.1.1.10
[root@srv3-cod ~]# ping -c3 ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=54 time=80.9 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=54 time=81.2 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=3 ttl=54 time=80.5 ms

--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 80.535/80.891/81.210/0.276 ms
[root@srv3-cod ~]# 
```

## ADM-HQ:

На текущий момент должна быть полная связность:

```bash
[user@adm-hq ~]$ ping -c3 srv-hq
PING srv-hq.au.team (10.1.1.10) 56(84) bytes of data.
64 bytes from srv-hq.au.team (10.1.1.10): icmp_seq=1 ttl=63 time=1.11 ms
64 bytes from srv-hq.au.team (10.1.1.10): icmp_seq=2 ttl=63 time=0.875 ms
64 bytes from srv-hq.au.team (10.1.1.10): icmp_seq=3 ttl=63 time=1.05 ms

--- srv-hq.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.875/1.010/1.109/0.099 ms
[user@adm-hq ~]$ ping -c3 fw-hq
PING fw-hq.au.team (10.1.1.1) 56(84) bytes of data.
64 bytes from fw-hq.au.team (10.1.1.1): icmp_seq=1 ttl=64 time=0.462 ms
64 bytes from fw-hq.au.team (10.1.1.1): icmp_seq=2 ttl=64 time=0.495 ms
64 bytes from fw-hq.au.team (10.1.1.1): icmp_seq=3 ttl=64 time=0.502 ms

--- fw-hq.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.462/0.486/0.502/0.017 ms
[user@adm-hq ~]$ ping -c3 cli-hq
PING cli-hq.au.team (10.1.2.128) 56(84) bytes of data.
64 bytes from 10.1.2.128: icmp_seq=1 ttl=63 time=0.837 ms
64 bytes from 10.1.2.128: icmp_seq=2 ttl=63 time=0.901 ms
64 bytes from 10.1.2.128: icmp_seq=3 ttl=63 time=0.943 ms

--- cli-hq.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.837/0.893/0.943/0.043 ms
[user@adm-hq ~]$ ping -c3 rtr-br
PING rtr-br.au.team (10.2.0.1) 56(84) bytes of data.
64 bytes from rtr-br.au.team (10.2.0.1): icmp_seq=1 ttl=63 time=43.1 ms
64 bytes from rtr-br.au.team (10.2.0.1): icmp_seq=2 ttl=63 time=41.4 ms
64 bytes from rtr-br.au.team (10.2.0.1): icmp_seq=3 ttl=63 time=39.6 ms

--- rtr-br.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 39.599/41.369/43.068/1.417 ms
[user@adm-hq ~]$ ping -c3 fw-br
PING fw-br.au.team (10.2.0.2) 56(84) bytes of data.
64 bytes from fw-br.au.team (10.2.0.2): icmp_seq=1 ttl=63 time=49.2 ms
64 bytes from fw-br.au.team (10.2.0.2): icmp_seq=2 ttl=63 time=46.3 ms
64 bytes from fw-br.au.team (10.2.0.2): icmp_seq=3 ttl=63 time=44.8 ms

--- fw-br.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 44.848/46.771/49.201/1.812 ms
[user@adm-hq ~]$ ping -c3 srv-br
PING srv-br.au.team (10.2.1.10) 56(84) bytes of data.
64 bytes from srv-br.au.team (10.2.1.10): icmp_seq=1 ttl=62 time=28.2 ms
64 bytes from srv-br.au.team (10.2.1.10): icmp_seq=2 ttl=62 time=26.1 ms
64 bytes from srv-br.au.team (10.2.1.10): icmp_seq=3 ttl=62 time=24.4 ms

--- srv-br.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 24.395/26.210/28.167/1.543 ms
[user@adm-hq ~]$ ping -c3 cli-br
PING cli-br.au.team (10.2.2.2) 56(84) bytes of data.
64 bytes from 10.2.2.2: icmp_seq=1 ttl=62 time=16.2 ms
64 bytes from 10.2.2.2: icmp_seq=2 ttl=62 time=16.1 ms
64 bytes from 10.2.2.2: icmp_seq=3 ttl=62 time=15.8 ms

--- cli-br.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 15.751/16.006/16.189/0.186 ms
[user@adm-hq ~]$ ping -c3 rtr-cod
PING rtr-cod.au.team (172.16.1.254) 56(84) bytes of data.
64 bytes from rtr-cod.au.team (172.16.1.254): icmp_seq=1 ttl=63 time=14.5 ms
64 bytes from rtr-cod.au.team (172.16.1.254): icmp_seq=2 ttl=63 time=12.6 ms
64 bytes from rtr-cod.au.team (172.16.1.254): icmp_seq=3 ttl=63 time=11.4 ms

--- rtr-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 11.430/12.826/14.468/1.252 ms
[user@adm-hq ~]$ ping -c3 sw-cod
PING sw-cod.au.team (172.16.1.0) 56(84) bytes of data.
64 bytes from sw-cod.au.team (172.16.1.0): icmp_seq=1 ttl=63 time=20.2 ms
64 bytes from sw-cod.au.team (172.16.1.0): icmp_seq=2 ttl=63 time=19.0 ms
64 bytes from sw-cod.au.team (172.16.1.0): icmp_seq=3 ttl=63 time=17.8 ms

--- sw-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 17.845/19.020/20.249/0.982 ms
[user@adm-hq ~]$ ping -c3 ha1-cod
PING ha1-cod.au.team (172.16.0.1) 56(84) bytes of data.
64 bytes from ha1-cod.au.team (172.16.0.1): icmp_seq=1 ttl=63 time=16.8 ms
64 bytes from ha1-cod.au.team (172.16.0.1): icmp_seq=2 ttl=63 time=15.8 ms
64 bytes from ha1-cod.au.team (172.16.0.1): icmp_seq=3 ttl=63 time=16.0 ms

--- ha1-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 15.790/16.205/16.794/0.427 ms
[user@adm-hq ~]$ ping -c3 ha2-cod
PING ha2-cod.au.team (172.16.0.2) 56(84) bytes of data.
64 bytes from ha2-cod.au.team (172.16.0.2): icmp_seq=1 ttl=63 time=16.2 ms
64 bytes from ha2-cod.au.team (172.16.0.2): icmp_seq=2 ttl=63 time=16.5 ms
64 bytes from ha2-cod.au.team (172.16.0.2): icmp_seq=3 ttl=63 time=15.9 ms

--- ha2-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 15.918/16.210/16.528/0.249 ms
[user@adm-hq ~]$ ping -c3 srv1-cod
PING srv1-cod.au.team (172.16.1.1) 56(84) bytes of data.
64 bytes from srv1-cod.au.team (172.16.1.1): icmp_seq=1 ttl=63 time=60.2 ms
64 bytes from srv1-cod.au.team (172.16.1.1): icmp_seq=2 ttl=63 time=58.0 ms
64 bytes from srv1-cod.au.team (172.16.1.1): icmp_seq=3 ttl=63 time=56.9 ms

--- srv1-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 56.862/58.348/60.197/1.385 ms
[user@adm-hq ~]$ ping -c3 srv2-cod
PING srv2-cod.au.team (172.16.1.2) 56(84) bytes of data.
64 bytes from srv2-cod.au.team (172.16.1.2): icmp_seq=1 ttl=63 time=17.4 ms
64 bytes from srv2-cod.au.team (172.16.1.2): icmp_seq=2 ttl=63 time=16.8 ms
64 bytes from srv2-cod.au.team (172.16.1.2): icmp_seq=3 ttl=63 time=16.4 ms

--- srv2-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 16.392/16.869/17.372/0.400 ms
[user@adm-hq ~]$ ping -c3 srv3-cod
PING srv3-cod.au.team (172.16.1.3) 56(84) bytes of data.
64 bytes from srv3-cod.au.team (172.16.1.3): icmp_seq=1 ttl=63 time=17.3 ms
64 bytes from srv3-cod.au.team (172.16.1.3): icmp_seq=2 ttl=63 time=15.7 ms
64 bytes from srv3-cod.au.team (172.16.1.3): icmp_seq=3 ttl=63 time=16.6 ms

--- srv3-cod.au.team ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 15.735/16.539/17.269/0.628 ms
[user@adm-hq ~]$ 
```

## HA1-COD, HA2-COD, SRV1-COD, SRV2-COD, SRV3-COD:

```bash
sed -i "s/#PermitRootLogin without-password/PermitRootLogin yes/g" /etc/openssh/sshd_config
systemctl restart sshd
```

## ADM-HQ:

Установим ansible:
- из-под root:

```bash
apt-get install -y python3-module-pip
```

- из-под user:

```bash
ssh-keygen -t rsa
```

```bash
for i in ha1 ha2 srv1 srv2 srv3;
do
ssh-copy-id root@$i-cod
done
```

```bash
mkdir /home/user/ansible
cd /home/user/ansible
```

```bash
python3 -m venv venv/ansible
```

```bash
source venv/ansible/bin/activate
pip install --upgrade pip
pip install ansible
```

Настраиваем ansible:

```bash
cat <<EOF > ansible.cfg
[defaults]
host_key_checking = False
EOF
```

```bash
mkdir -p inventories/production
```

```bash
cat <<EOF > inventories/production/hosts
all:
  children:
    proxy:
      hosts:
        ha1-cod:
        ha2-cod:
    server:
      hosts:
        srv1-cod:
        srv2-cod:
        srv3-cod:
EOF
```

```bash
mkdir inventories/production/group_vars
```

```bash
cat <<EOF > inventories/production/group_vars/all.yml
---
ansible_python_interpreter: /usr/bin/python3
ansible_ssh_user: root
ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF
```

Проверить:

```bash
(ansible) [user@adm-hq ansible]$ ansible -i inventories/production/hosts -m ping all
ha2-cod | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
srv2-cod | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ha1-cod | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
srv1-cod | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
srv3-cod | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
(ansible) [user@adm-hq ansible]$ 
```

```bash
cat << EOF > playbook1_keepalived.yml
- name: Install and settings keepalived for HA1-COD and HA2-COD
  hosts: proxy
  become: true

  tasks:
    - name: Install package 'keepalived'
      community.general.apt_rpm:
        name: "keepalived"
        state: present
        update_cache: true

- hosts: ha1-cod
  become: true

  tasks:
    - name: Copy the 'keepalived.conf' file for MASTER
      ansible.builtin.template:
        src: templates/keepalived-master.conf.j2
        dest: /etc/keepalived/keepalived.conf
        owner: root
        group: root
        mode: '0644'

- hosts: ha2-cod
  become: true

  tasks:
    - name: Copy the 'keepalived.conf' file for BACKUP
      ansible.builtin.template:
        src: templates/keepalived-backup.conf.j2
        dest: /etc/keepalived/keepalived.conf
        owner: root
        group: root
        mode: '0644'

- hosts: proxy
  become: true

  tasks:
    - name: Started and enabled keepalived
      ansible.builtin.systemd:
        name: keepalived
        state: started
        enabled: true
EOF
```

```bash
mkdir templates
```

```bash
cat <<EOF > templates/keepalived-master.conf.j2
global_defs {
    enable_script_security
    max_auto_priority
}

vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance VI_1 {
  interface {{ keepalived_interface_name }}
  state MASTER

  virtual_router_id 51
  priority 101

  virtual_ipaddress {
    {{ keepalived_virtual_ipaddress }}
  }

  track_script {
    chk_haproxy
  }
}
EOF
```

```bash
cat <<EOF > templates/keepalived-backup.conf.j2
global_defs {
    enable_script_security
    max_auto_priority
}

vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance VI_1 {
  interface {{ keepalived_interface_name }}
  state BACKUP

  virtual_router_id 51
  priority 100

  virtual_ipaddress {
    {{ keepalived_virtual_ipaddress }}
  }

  track_script {
    chk_haproxy
  }
}
EOF
```

```bash
cat <<EOF > inventories/production/group_vars/proxy.yml
keepalived_interface_name: "ens19"
keepalived_virtual_ipaddress: "172.16.1.253/23"
EOF
```

Запускаем, результат:

```bash
(ansible) [user@adm-hq ansible]$ ansible-playbook -i inventories/production/hosts playbook1_keepalived.yml 

PLAY [Install and settings keepalived for HA1-COD and HA2-COD] *******************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************
ok: [ha1-cod]
ok: [ha2-cod]

TASK [Install package 'keepalived'] **********************************************************************************************************************************************
changed: [ha2-cod]
changed: [ha1-cod]

PLAY [ha1-cod] *******************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************
ok: [ha1-cod]

TASK [Copy the 'keepalived.conf' file for MASTER] ********************************************************************************************************************************
changed: [ha1-cod]

PLAY [ha2-cod] *******************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************
ok: [ha2-cod]

TASK [Copy the 'keepalived.conf' file for BACKUP] ********************************************************************************************************************************
changed: [ha2-cod]

PLAY [proxy] *********************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************
ok: [ha2-cod]
ok: [ha1-cod]

TASK [Started and enabled keepalived] ********************************************************************************************************************************************
changed: [ha2-cod]
changed: [ha1-cod]

PLAY RECAP ***********************************************************************************************************************************************************************
ha1-cod                    : ok=6    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ha2-cod                    : ok=6    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

(ansible) [user@adm-hq ansible]$ 
```

Проверить, наличие VIP:

```bash
(ansible) [user@adm-hq ansible]$ ssh root@ha1-cod
Last login: Thu Feb 26 08:59:33 2026 from 10.0.2.1
[root@ha1-cod ~]# ip -c -br -4 a
lo               UNKNOWN        127.0.0.1/8 
ens19            UP             172.16.0.1/23 172.16.1.253/23 
[root@ha1-cod ~]# exit
Connection to ha1-cod closed.
(ansible) [user@adm-hq ansible]$ 
```

Делаем дальше:

```bash
cat <<EOF > playbook2_web.yml
---
- name: Install Installing the Angie Web Server
  hosts: server
  become: true
  
  tasks:
    - name: Install package 'angie'
      community.general.apt_rpm:
        name: "angie"
        state: present
        update_cache: true
        
    - name: Copy the 'index.html' file
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: /usr/share/angie/html/index.html
        owner: root
        group: root
        mode: '0644'
        
    - name: Started and enabled angie
      ansible.builtin.systemd:
        name: angie
        state: started
        enabled: true
EOF
```

```bash
cat <<EOF > templates/index.html.j2
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>{{ ansible_facts['hostname'] }} by Angie!</h1>
   </body>
</html>
EOF
```

Запускаем, результат:

```bash
(ansible) [user@adm-hq ansible]$ ansible-playbook -i inventories/production/hosts playbook2_web.yml 

PLAY [Install Installing the Angie Web Server] ***********************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************
ok: [srv3-cod]
ok: [srv2-cod]
ok: [srv1-cod]

TASK [Install package 'angie'] ***************************************************************************************************************************************************
changed: [srv3-cod]
changed: [srv1-cod]
changed: [srv2-cod]

TASK [Copy the 'index.html' file] ************************************************************************************************************************************************
changed: [srv2-cod]
changed: [srv3-cod]
changed: [srv1-cod]

TASK [Started and enabled angie] *************************************************************************************************************************************************
changed: [srv3-cod]
changed: [srv1-cod]
changed: [srv2-cod]

PLAY RECAP ***********************************************************************************************************************************************************************
srv1-cod                   : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
srv2-cod                   : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
srv3-cod                   : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

(ansible) [user@adm-hq ansible]$ 
```

Проверить:

```bash
(ansible) [user@adm-hq ansible]$ curl http://srv1-cod
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>srv1-cod by Angie!</h1>
   </body>
</html>
(ansible) [user@adm-hq ansible]$ curl http://srv2-cod
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>srv2-cod by Angie!</h1>
   </body>
</html>
(ansible) [user@adm-hq ansible]$ curl http://srv3-cod
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>srv3-cod by Angie!</h1>
   </body>
</html>
(ansible) [user@adm-hq ansible]$ 
```

Делаем дальше:

```bash
cat <<EOF > playbook3_haproxy.yml
---
- name: Install and settings haproxy for HA1-COD and HA2-COD
  hosts: proxy
  become: true

  tasks:
    - name: Install package 'haproxy'
      community.general.apt_rpm:
        name: "haproxy"
        state: present
        update_cache: true

    - name: Copy the 'haproxy.cfg' file
      ansible.builtin.template:
        src: templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        owner: root
        group: root
        mode: '0644'

    - name: Started and enabled haproxy
      ansible.builtin.systemd:
        name: haproxy
        state: started
        enabled: true
EOF
```

```bash
cat <<EOF > templates/haproxy.cfg.j2
global
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    daemon

defaults
    log     global
    mode    http
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

frontend main
    bind {{ haproxy_frontend_bind_address }}:{{ haproxy_frontend_bind_port }}
    default_backend             app

backend app
    balance     roundrobin
    option httpchk GET /
    http-request set-header X-Forwarded-For %[src]
    http-request set-header X-Forwarded-Proto http
{% for record in haproxy_backend_add_hosts %}
    server {{ record.name }} {{ record.address }}:80 check
{% endfor %}

listen stats
    bind *:9000
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /haproxy_stats
EOF
```

```bash
cat <<EOF >> inventories/production/group_vars/proxy.yml

haproxy_frontend_bind_address: "0.0.0.0"
haproxy_frontend_bind_port: "80"
haproxy_backend_add_hosts:
  - name: "srv1-cod"
    address: "172.16.1.1"
  - name: "srv2-cod"
    address: "172.16.1.2"
  - name: "srv3-cod"
    address: "172.16.1.3"
EOF
```

Запускаем, результат:

```bash
(ansible) [user@adm-hq ansible]$ ansible-playbook -i inventories/production/hosts playbook3_haproxy.yml 

PLAY [Install and settings haproxy for HA1-COD and HA2-COD] **********************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************
ok: [ha1-cod]
ok: [ha2-cod]

TASK [Install package 'haproxy'] *************************************************************************************************************************************************
changed: [ha2-cod]
changed: [ha1-cod]

TASK [Copy the 'haproxy.cfg' file] ***********************************************************************************************************************************************
changed: [ha1-cod]
changed: [ha2-cod]

TASK [Started and enabled haproxy] ***********************************************************************************************************************************************
changed: [ha2-cod]
changed: [ha1-cod]

PLAY RECAP ***********************************************************************************************************************************************************************
ha1-cod                    : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ha2-cod                    : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

(ansible) [user@adm-hq ansible]$ 
```

Проверить:

```bash
(ansible) [user@adm-hq ansible]$ curl http://172.16.1.253
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>srv3-cod by Angie!</h1>
   </body>
</html>
(ansible) [user@adm-hq ansible]$ curl http://172.16.1.253
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>srv1-cod by Angie!</h1>
   </body>
</html>
(ansible) [user@adm-hq ansible]$ curl http://172.16.1.253
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>srv2-cod by Angie!</h1>
   </body>
</html>
(ansible) [user@adm-hq ansible]$ 
```

![Haproxy_Check_stats](img/Haproxy_Check_stats.png)

## SRV-BR:

Развернём Nextcloud 33 версии, чтобы было что публиковать наружу:

```bash
apt-get update && apt-get install -y apache2 apache2-mod_ssl apache2-mod_php8.4 php8.4 php8.4-{pgsql,pdo_pgsql,curl,dom,exif,fileinfo,gd2,gmp,imagick,intl,libs,mbstring,memcached,opcache,openssl,pcntl,pdo,xmlreader,zip,ldap}
```

```bash
for i in dir env headers mime rewrite;do a2enmod $i;done
```

```bash
systemctl enable --now httpd2
```

```bash
wget https://download.nextcloud.com/server/releases/nextcloud-33.0.0.zip
```

```bash
unzip nextcloud-33.0.0.zip && rm -f nextcloud-33.0.0.zip
```

```bash
cp -r nextcloud /var/www/html/ && rm -rf nextcloud
```

```bash
chown -R root /var/www/html/nextcloud
mkdir /var/www/html/nextcloud/data
chown -R apache2 /var/www/html/nextcloud/{apps,config,data}/
```

```bash
cat <<EOF > /etc/httpd2/conf/sites-available/nextcloud.conf
<VirtualHost *:80>
  DocumentRoot /var/www/html/nextcloud/

  <Directory /var/www/html/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
EOF
```

```bash
ln -s /etc/httpd2/conf/sites-available/nextcloud.conf /etc/httpd2/conf/sites-enabled/
systemctl restart httpd2
```

```bash
apt-get install -y postgresql17-server
```

```bash
/etc/init.d/postgresql initdb
```

```bash
systemctl enable --now postgresql
```

```bash
su - postgres -s /bin/bash -c 'createuser --no-superuser --no-createdb --no-createrole --encrypted --pwprompt nextclouduser'
```

```bash
su - postgres -s /bin/bash -c 'createdb -O nextclouduser nextclouddb'
```

## ADM-HQ:

Переходим в веб-браузер на http://srv-br.au.team/, создаём учётную запись для администратора, а также указываем данные для подключения к СУБД:

![Nextcloud1](img/Nextcloud1.png)

![Nextcloud2](img/Nextcloud2.png)

Результат:

![Nextcloud3](img/Nextcloud3.png)

Для настройки интеграции базы пользователей с LDAP необходимо в списке приложений Nextcloud включить приложение «LDAP user and group backend»:

![Nextcloud_LDAP_Activate](img/Nextcloud_LDAP_Activate.png)

Сама настройка **LDAP/AD интеграция** может выглядеть следующим образом:

![Nextcloud_LDAP1](img/Nextcloud_LDAP1.png)

![Nextcloud_LDAP2](img/Nextcloud_LDAP2.png)

![Nextcloud_LDAP4](img/Nextcloud_LDAP4.png)

Результат:

![Nextcloud_LDAP_Check](img/Nextcloud_LDAP_Check.png)

![Nextcloud_LDAP_Check_User](img/Nextcloud_LDAP_Check_User.png)

Добавляем обратный прокси для безопасной публикации в рамках локальной сети:

![HQ-FW_ReverseProxy](img/HQ-FW_ReverseProxy.png)

Также CNAME-запись в DNS:

![CNAME_Nextcloud](img/CNAME_Nextcloud.png)

## SRV-BR:

Правим файл `/var/www/html/nextcloud/config/config.php` добавив строку:

![Nextcloud_Fixed_Domainname](img/Nextcloud_Fixed_Domainname.png)

## ADM-HQ:

Результат:

![Nextcloud_Check_Proxy](img/Nextcloud_Check_Proxy.png)

Создадим CNAME-запись для www, развёрнутого в ЦОД-е:

![WEB_DNS](img/WEB_DNS.png)

Добавляем обратный прокси для безопасной публикации в рамках локальной сети:

![HQ-FW_ReverseProxyPortal](img/HQ-FW_ReverseProxyPortal.png)

Результат:

![Check_Portal](img/Check_Portal.png)

Создадим CNAME-запись для публикации личного кабинета в локальной сети:

![LK_CNAME](img/LK_CNAME.png)

Опубликуем личный кабинет как из локальной сети по имени, так и из внешней сети по публичному IP:

![LK_ReverseProxy](img/LK_ReverseProxy.png)

Настроим ЛК, для работы с ресурсами SSL VPN:

![SSL_VPN](img/SSL_VPN.png)

![SSL_VPN_Rules](img/SSL_VPN_Rules.png)

Результат, из локальной сети:

![LK_Access1](img/LK_Access1.png)

![LK_Access](img/LK_Access2.png)

![LK_Access3](img/LK_Access3.png)

![LK_Access4](img/LK_Access4.png)

## OUT-CLI:

База
- имя
- адресация

![OUT-CLI_Base](img/OUT-CLI_Base.png)

Заходим в личный кабинет по публичному адреса FW-HQ, скачиваем сертификат, добавляем, ожидаемый результат:

![OUT-CLI_Check_Access](img/OUT-CLI_Check_Access.png)
