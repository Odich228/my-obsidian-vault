```
machine set hostname fw-br.au.team
iplir stop
inet ifconfig eth1 class trunk
inet ifconfig eth1 vlan add 10
inet ifconfig eth1 vlan add 20
inet ifconfig eth1.10 address 10.2.1.14 netmask 255.255.255.240
inet ifconfig eth1.20 address 10.2.2.1 netmask 255.255.255.128

Откройте для редактирования конфигурационный файл `iplir.conf`:

iplir config

- В секции `[adapter]` с описанием интерфейса, к которому подключен коммутатор, присвойте параметру `allowtraffic` значение `off`:

[adapter]
name= eth1
allowtraffic= off
type= internal


- Добавьте секции `[adapter]`, описывающие созданные виртуальные интерфейсы:

[adapter]
name= eth1.10
allowtraffic= on
type= internal

[adapter]
name= eth1.20
allowtraffic= on
type= internal

inet ifconfig eth1 up
iplir start
