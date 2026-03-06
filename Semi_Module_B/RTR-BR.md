```
en
conf t
hostname rtr-br
ip domain-name au.team

username net_admin
password P@ssw0rd
role admin
exit

inteface e0
description "to-ISP"
ip address 84.212.78.78/27
exit

interface e1
description "to-FW-BR"
ip address 10.2.0.1/30
exit

port te0
service-instance ISP
encapsulation untagged 
connect ip interface e0 
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

write memory
