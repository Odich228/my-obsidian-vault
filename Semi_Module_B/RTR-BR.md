```
en
conf t
hostname rtr-br
ip domain-name au.team

username net_admin
password P@ssw0rd
role admin
exit

interface int0
description "to-ISP"
ip address 84.212.78.78/27
exit

interface int1
description "to-FW-BR"
ip address 10.2.0.1/30
exit

port te0
service-instance ISP
encapsulation untagged 
connect ip interface int0 
exit
exit

port te1
service-instance FW-BR
encapsulation untagged 
connect ip interface int1
exit
exit

interface loopback.0
ip address 192.168.255.2/32
no shutdown 
exit

router isis
net 49.0001.1921.6825.5002.00
is-type level-2-only
metric-style wide
passive-interface loopback.0 
exit

interface int0 
ip router isis
isis circuit-type level-2-only
isis network point-to-point
exit

interface loopback.0
ip router isis
exit

router bgp 64499
bgp router-id 192.168.255.2
bgp log-neighbor-changes
neighbor 192.168.255.1 remote-as 64499
neighbor 192.168.255.1 update-source loopback.0
neighbor 192.168.255.1 description iBGP-to-ISP
address-family ipv4 unicast
neighbor 192.168.255.1 activate
neighbor 192.168.255.1 next-hop-self
exit-address-family
exit

interface int0
ip nat outside
exit

interface int1
ip nat inside
exit
ip nat pool BR 10.2.0.1-10.2.2.126
ip nat source dynamic inside-to-outside pool BR overload interface int0
write memory


router ospf 1
passive-interface default
no passive-interface int1 
network 10.2.0.0/30 area 0
default-information originate
exit

write memory

interface tunnel.1
description "GRE-to-FW-HQ"
ip address 10.0.1.2/30
ip tunnel 84.212.78.78 63.27.18.18 mode gre
exit

ip route 10.1.1.0/27 10.0.1.1
ip route 10.1.1.32/28 10.0.1.1
ip route 10.1.2.0/24 10.0.1.1



interface tunnel.3
description "GRE-to-RTR-COD"
ip address 10.0.3.2/30
ip tunnel 84.212.78.78 34.95.33.33 mode gre
exit

router ospf 2
passive-interface default
no passive-interface tunnel.3
network 10.0.3.0/30 area 0
exit
write memory
