
1. Создать пару ключей
```
ssh-keygen -t ed25519
```
2. Обменятся  .ssh/id_ed25519.pub в .ssh/authorized_keys (любым способом)
3. Установить пакеты rsync и unison:
```
apt-get install rsync unison
```
4. Для того чтобы при повторной работе `unison` использовал существующее SSH-соединение вместо установки нового, необходимо выполнить следующие команды
```
mkdir ~/.ssh/ctl

cat << EOF > ~/.ssh/config
Host *
ControlMaster auto
ControlPath ~/.ssh/ctl/%h_%p_%r
ControlPersist 1
EOF
```
%% Сомнительно, но окэй %%
5. Создать файл для записи журнала репликации
```
touch /var/log/sysvol-sync.log
```
6. Создать каталог для конфигурации Unison `/root/.unison/`:
```
mkdir /root/.unison
```
7. Создать файл конфигурации Unison
```
cat << EOF > /root/.unison/sync_Lin-DC2.prf
# Список каталогов, которые будут синхронизированы
root = /var/lib/samba
# После имени хоста используются два символа /
root = ssh://root@Lin-DC2.semifinal.irpo//var/lib/samba
# Список подкаталогов, которые нужно синхронизировать
path = sysvol
# Список подкаталогов, которые нужно игнорировать
#ignore = Path

acl=true
xattrs=true
auto=true
batch=true
perms=0
rsync=true
maxthreads=1
retry=3
confirmbigdeletes=false
servercmd=/usr/bin/unison
copythreshold=0
copymax = 1

# Сохранять журнал с результатами работы в отдельном файле
logfile = /var/log/sysvol-sync.log
EOF
```
8. Первая синхронизация (создается структура)

```
/usr/bin/rsync -XAavz --log-file /var/log/sysvol-sync.log \
--delete-after -f"+ */" -f"- *" /var/lib/samba/sysvol \
root@Lin-DC2.semifinal.irpo:/var/lib/samba && /usr/bin/unison
```
9. Создать задание
```
EDITOR=vim crontab -e

*/5 * * * * /usr/bin/unison -silent
```
##### Синхронизация idmap.ldb
Синхронизации idmap.ldb можно избежать, если на всех контроллерах добавить следующие параметры в smb.conf в секции [sysvol] (и в [netlogon]) строки:

```
vim /etc/samba/smb.conf 

acl_xattr:ignore system acls = yes
acl_xattr:default acl style = windows
```