#### заменяешь [[Ultimate Kerberos]]

#### Ставим софтину 

```
apt-get update && apt-get install admc gpui admx-basealt admx-chromium admx-msi-setup
admx-msi-setup
```
#### Меняем dns
```
В acc ставишь днс на 192.168.1.2
```
#### Получаешь tgt
```
kinit admin@SEMIFINAL.IRPO
klist
```

#### Перенос FSMO
```
В ADMC
В верхней шторке выбираешь "Файл" ==> "Мастера Операций"
	Заменяешь на lin-dc1.semifinal.irpo (предложит автоматом)
Переходишь во вкладку "Центр управления Active Directory"
	на каждую тыкаешь захватить
```

##### Если всё пойдёт по ... (а у тебя пойдёт)
```
На Lin-DC1
	samba-tool fsmo transfer --role=all -U admin
	samba-tool fsmo show
```