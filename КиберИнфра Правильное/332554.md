1. меняем /etc/krb5.conf
2. ставим софт
```
apt-get update && apt-get install admc gpui admx-basealt admx-chromium admx-msi-setup
admx-msi-setup
```
Получаем билет
```
kinit admin@SEMIFINAL.IRPO
klist
```
Перенос ролей FSMO
ADMC в графике
или 
```
samba-tool fsmo transfer --role=
```
проверка
```
samba-tool fsmo show
```
в случае проблем
```
samba-tool fsmo transfer --role=all -U admin
samba-tool fsmo seize --force --role=domaindns
samba-tool fsmo seize --force --role=forestdns
```
