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



