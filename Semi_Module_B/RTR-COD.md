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
exit
port te1
service-instance te1/int1
encapsulation untagged
connect ip interface int1
exit
exit
write memory
router bgp 64499
bgp router-id 34.95.33.33
neighbor 34.95.33.254 remote-as 64499
exit
write memory
interface int0
ip nat outside
exit
interface int1
ip nat inside
exit
ip nat pool COD 172.16.0.1-172.16.1.254
ip nat source dynamic inside-to-outside pool COD overload interface int0
write memory
interface tunnel.2
description "GRE-to-FW-HQ"
ip address 10.0.2.2/30
ip tunnel 34.95.33.33 63.27.18.18 mode gre
exit
interface tunnel.3
description "GRE-to-RTR-BR"
ip address 10.0.3.1/30
ip tunnel 34.95.33.33 84.212.78.78 mode gre
exit
router ospf 1
passive-interface default
no passive-interface tunnel.3
network 10.0.3.0/30 area 0
network 172.16.0.0/23 area 0
exit
ip route 10.1.1.0/27 10.0.2.1
ip route 10.1.1.32/28 10.0.2.1
ip route 10.1.2.0/24 10.0.2.1
write memory
