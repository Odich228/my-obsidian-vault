```
en
conf t
hostname RTR-BR.au.team
ip domain-name au.team 
interface e1 
ip address 10.2.0.1/30
ip nat inside 
exit
port te1
service-instance FW-BR
encapsulation untagged 
connect ip interface e1
exit
exit
