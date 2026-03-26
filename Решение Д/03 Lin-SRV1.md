##### Базовая настройка  
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
Установка ПО
```
apt-get update && apt-get install samba samba-common-tools task-auth-ad-sssd -y
```
Получаем билет
[[Kerberos]]
```
kinit admin@SEMIFINAL.IRPO
klist
```
Вводим в домен
system-auth write ad semifinal.irpo Lin-SRV1 semifinal 'admin' 'P@ssw0rd' 
проверка
net ads testjoin
Создание и настройка директорий
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
проверка
ls -ldn /opt/samba/profiles /opt/samba/share /opt/UserDocs

##### Конфигурируем smb.conf
%% начала комментируем ; browseable = No %%
###### /etc/samba/smb.conf
```
[profiles]
comment = Users profiles
path = /opt/samba/profiles/
browseable = No
read only = No
vfs objects = acl_xattr

[share]
path = /srv/samba/share
guest ok = yes
public = yes
writable = yes
available = yes
force user = nobody

[UserDocs]
comment = Docs domain users
path = /opt/UserDocs
writable = yes
read list = @Domain Users
write list = @Domain Users
force group = Domain Users
force create mode = 666
force directory mode = 775
```
Включаем службы
systemctl enable --now smb avahi-daemon
systemctl status smb.service
Копируем из SYSVOL
копируем каталоги из C:\Windows\SYSVOL\<domainname> 
в SYSVOL Lin-DC1

[[Настройка прав на WIN-DC#^8fec9f]] 

Меняем **browseable = No**
smbcontrol all reload-config
меняем права на sysvol
samba-tool ntacl sysvolreset
Переходим на [[04 Win-CLI1]]
