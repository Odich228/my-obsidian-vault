```
enable
configure terminal
hostname rtr-cod
ip domain-name au.team
username net_admin
password P@ssw0rd
role admin
exit
interface int0
description "Connect-to-ISP"
ip address 34.95.33.33/24
exit
port te0
service-instance te0/int0
encapsulation untagged
connect ip interface int0
exit
exit
interface int1
description "Connect-to-SW-COD"
ip address 172.16.1.254/23

