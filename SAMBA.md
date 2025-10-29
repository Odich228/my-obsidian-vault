# Конфигурация сервера 
# Устанвока пакетов

apt-get install alterator-fbi
systemctl enable --now alteratord ahttpd
apt-get install alterator-net-domain task-samba-dc
apt-get install alterator-datetime
apt-get install alterator-net-eth


# Настройка параметров сети

hostnamectl set-hostname dc1.courses.alt
domainname courses.alt
systemctl stop smb nmb krb5kdc slapd bind dnsmasq
systemctl disable smb nmb krb5kdc slapd bind dnsmasq
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol

# Создание домена с командной строки

samba-tool domain provision --realm=courses.alt --domain courses \
--adminpass='Pa$$word' --dns-backend=SAMBA_INTERNAL \
--server-role=dc --use-rfc2307 (Тру способ)


