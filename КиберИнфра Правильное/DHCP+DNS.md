Выполняется на Lin-DC2
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

[Типы  SPN](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc772815(v=ws.10)#service-principal-names)

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
проверяем
```
kinit -5 -V -k -t /etc/dhcp/dhcpduser.keytab
```
**Примечание:** Если при проверке авторизации возникает ошибка:
*kinit: Client not found in Kerberos database while getting initial credentials*
Необходимо, например в [ADMC](https://www.altlinux.org/ADMC "ADMC"), изменить для пользователя значение параметра **userPrincipalName** на значение **servicePrincipalName + REALM** (в данном примере нужно поменять webauth на DHCP/Lin-DC2.semifinal.irpo@SEMIFINAL.IRPO).

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
Создаем конфигурационный файл /etc/dhcp/dhcpd.conf
[[конфиг вима]]
10. Запускаем DHCP
```
systemctl enable --now dhcpd
```
11. Проверка DHCP
Когда клиент получает адрес, видим в журнале что то типа:
```
==dhcpd[7817]: DHCPDISCOVER from 08:00:27:99:a6:1f via enp1s0==
==dhcpd[7817]: DHCPOFFER on 192.168.0.150 to 08:00:27:99:a6:1f (host-199) via enp1s0==
==dhcpd[7817]: Commit: IP: 192.168.0.150 DHCID: 08:00:27:99:a6:1f Name: host-199==
==dhcpd[7817]: execute_statement argv[0] = /usr/local/bin/dhcp-dyndns.sh==
==dhcpd[7817]: execute_statement argv[1] = add==
==dhcpd[7817]: execute_statement argv[2] = 192.168.0.150==
==dhcpd[7817]: execute_statement argv[3] = 08:00:27:99:a6:1f==
==dhcpd[7817]: execute_statement argv[4] = host-199==
==dhcpd[8228]: 18-06-25 14:55:31 [dyndns] : Getting new ticket, old one has expired==
==dhcpd[8236]: 'A' record changed, updating record.==
==dhcpd[8237]: Record deleted successfully==
==dhcpd[8240]: Record added successfully==
==dhcpd[8268]: Record added successfully==
==dhcpd[8271]: DHCP-DNS add succeeded==
==dhcpd[7817]: DHCPREQUEST for 192.168.0.125 (192.168.0.132) from 08:00:27:99:a6:1f (host-199) via enp1s0==
==dhcpd[7817]: DHCPACK on 192.168.0.150 to 08:00:27:99:a6:1f (host-199) via enp1s0==
```