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