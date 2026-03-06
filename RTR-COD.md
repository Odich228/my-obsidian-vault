```
enable
configure terminal
hostname rtr-cod
ip domain-name au.team

username net_admin
password P@ssw0rd
role admin
exit

interface e0
description "to-ISP"
ip address 34.95.33.33/24
exit

port te0
service-instance te0/int0
encapsulation untagged 
connect ip interface int0 
exit
exit

interface e1
description "to-SW-COD"
ip address 172.16.1.254/23
exit

port te1
service-instance te1/int1
encapsulation untagged 
connect ip interface int1
exit
exit

write memory