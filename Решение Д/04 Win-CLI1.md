###### 1. Заходим admin, ставим RSAT
```
WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
WindowsCapability -Name RSAT* -Online | Add-WindowsCapability –Online
```
###### 2. Меняем путь в GPO Profiles 
```
		\\Lin-SRV1.semifinal.irpo\profiles\%USERNAME%
```
###### 2. Далее под winuser1 обновляем политику
```
gpupdate /force
```
**перезагружаем** 

**смотрим на SRV1**
```
    ls -l /opt/samba/profiles/
```
Далее настраиваем второй контроллер домена на [[06 Lin-DC2]

