
Пользователь admin (для удобства)
Понижаем домен AD:
```
set-ADForestMode -Identity samba.alt -ForestMode Windows2012R2Forest
 set-ADDomainMode -Identity samba.alt -DomainMode windows2012R2Domain

set-ADForestMode -Identity samba.alt -ForestMode Windows2008R2Forest
set-ADDomainMode -Identity samba.alt -DomainMode windows2008R2Domain
```

Добавить в DNS A record
	 **Lin-DC1 192.168.1.3**

###### меняем на IP 192.168.1.100
##### Наст
раиваем права на профили пользователей

###### Настройка расширенных ACL
входим админом, настраиваем права
		
Domain Users 
		Права:
	Traverse folder / execute file
    List folder / read data	
	Create folder / append data	
Права на только **This folder only**  ^8fec9f

