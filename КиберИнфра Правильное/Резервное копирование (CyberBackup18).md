На хостах LIN-SRV1 и ADM
```
apt-get install kernel-source-6.12 kernel-headers-modules-6.12 gcc make kmod-sign -y
update-kernel
reboot
uname -r
```
проверяем наличие link build
```
ls -l /lib/modules/6.12.68-6.12-alt1/
```
Монтируем CD-ROM
```
mount /dev/sr0 /mnt
```
Содержимое
```
ls -l /mnt/
```
Устанавливаем CyberBackup, сначала на LIN-SRV1
```
bash /mnt/CyberBackup_18_64-bit.x86_64
```
![[Pasted image 20260309133033.png]]
###### На ADM

![[Pasted image 20260309135615.png]]
