==**Настройка интерфейса==** 

`interface <интерфейс>`
	`ip address <адрес/маска>`
	`ip nat outside/inside` 
	`exit`

`port <порт>`
	`service -instance <номер>`
	`encapsulation untagged`
	`connect ip interface <интерфейс>`
	`exit`

	ip route 0.0.0.0/0 <шлюз по умолчанию>

==Настройка GRE== 

`interface tunnel.0`
	`ip address <адрес/маска>`
	`ip mtu 1400`
	`ip tunnel <адрес м1> <адрес м2> mode gre`
	`exit`

==Настройка OSPF== 
	`router ospf 1`
		`router-id <ip роутера>`
		`network <сеть> area 0`
		`passive-interface default`
		`no passive-interface tunnel.0`
	
	interface tunnel.0
	 ip ospf message-digest-key 1 md5 P@ssw0rd
	 ip ospf authentication message-digest

VLAN
`interface <name interface>`
	`ip adddress <ip address>`
	 `description <name vlan>`
	 `no shutdown`
	 `exit`
`port <name port>`
	`service-instance <name service>`
		`encapsulation <tagged/untagged>`
		`rewrite pop 1` 
		`connect ip interface <name interface>`