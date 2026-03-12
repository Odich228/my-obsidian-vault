1. Установить pam_mount:
```
apt-get install pam_mount cifs-utils
```
2. Для того чтобы файловые ресурсы, подключенные с помощью pam_mount, корректно отключались при завершении сеанса
```
apt-get install systemd-settings-enable-kill-user-processes
```
3. Добавить pam_mount в схему аутентификации по умолчанию. Для этого в конец файла `/etc/pam.d/system-auth` необходимо добавить строки:
```
session         [success=1 default=ignore] pam_succeed_if.so  service = systemd-user quiet
session         optional        pam_mount.so disable_interactive
```
4. Установить правило монтирования ресурса в файле `/etc/security/pam_mount.conf.xml` (перед тегом <cifsmount>):
```
<volume 
	uid="10000-2000200000" 
	fstype="cifs" 
	server="Lin-SRV1.semifinal.irpo" 
	path="UserDocs"
	mountpoint="/home/SEMIFINAL.IRPO/%(USER)/DomainDocs" 
	options="sec=krb5,vers=2.0,cruid=%(USERUID),nounix,uid=%(USERUID),gid=%(USERGID),file_mode=0664,dir_mode=0775" />
```
где
**uid="10000-2000200000"** — диапазон присваиваемых для доменных пользователей UID (подходит для Winbind и для SSSD);
server="**c228**" — имя сервера с ресурсом;
path="**sysvol**" — имя файлового ресурса;
mountpoint="**~/share**" — путь монтирования в домашней папке пользователя.


Для проверки можно попробовать смонтировать ресурс в сессии:
```
mount.cifs //Lin-SRV1.semifinal.irpo/UserDocs /mnt/  -o vers=2.0,user=linuser1
```