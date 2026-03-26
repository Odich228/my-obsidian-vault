#### Базовая настройка  
**имени**
```
hostnamectl hostname Lin-SRV1.semifinal.irpo
domainname semifinal.irpo
exec bash
```
**и сети**
```
echo "TYPE=eth" > /etc/net/ifaces/ens18/options
echo "192.168.1.4/24" > /etc/net/ifaces/ens18/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/ens18/ipv4route
echo -e "nameserver 192.168.1.3\nsearch semifinal.irpo" > /etc/net/ifaces/ens18/resolv.conf

systemctl restart network
```
#### Установка ПО
```
apt-get update && apt-get install samba samba-common-tools task-auth-ad-sssd -y
```
#### заменяешь [[Ultimate Kerberos]]

#### Получаешь tgt
```
kinit admin@SEMIFINAL.IRPO
klist
```
#### Вводим в домен
```
system-auth write ad semifinal.irpo Lin-SRV1 semifinal 'admin' 'P@ssw0rd' 
```
#### Проверка
```
net ads testjoin
```
#### Создание и настройка директорий
```
mkdir -p /opt/samba/profiles
chown root:"Domain Admins" /opt/samba/profiles
chmod 0770 /opt/samba/profiles

mkdir -p /srv/samba/share
chown nobody:nobody /srv/samba/share
chmod 0775 /srv/samba/share

mkdir/opt/samba/UserDocs
chown -R root:"SEMIFINAL.IRPO\\Domain Users" /opt/samba/UserDocs
chmod -R 2775 /opt/samba/UserDocs
```