srv2-cod:
apt-get update && apt-get install -y scsitarget-utils

Включить tgt
systemctl enable --now tgt

Смотрим диск который будем использовать (lsblk)
В /etc/tgt/targets.conf:
<target iqn.2026-12.region.ssa2026.cod:data.target>
		ditrect-store /dev/sda
</target>

Перезапустить tgt

проверка:
tgtadm --lld iscsi --op show --mode target



Указываем что бы LVM не сканил ISCSI диски в /etc/lvm/lvm.conf:

filter = [ "rl/dev/sdl" ]

srv1-cod
- Установим пакет **open-iscsi**:

```
apt-get update && apt-get install -y open-iscsi
```

- Включаем и добавляем в автозагрузку службу **iscsid**:

```
systemctl enable --now iscsid
```

- Посмотреть доступные для подключения target-ы можно с помощью команды:

```
iscsiadm -m discovery -t sendtargets -p 192.168.20.2
```

- Подключить target-ы:
    

```
iscsiadm -m node --login
```

в файле /etc/iscsi/iscsid.conf:
- закомментировать **node.startup = manual**
- раскомментировать **node.startup = automatic**

В файле **/var/lib/iscsi/send_targets/<TargetServer>,<Port>/st_config** внести изменения:

discovery.sendtargets.use_discoveryd = Yes

Затем:
reboot
после этого диск должен появится 