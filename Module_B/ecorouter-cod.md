en
conf t
hostname rtr-cod
ip domain-name cod.ssa2026.region
interface wan 
ip address 178.207.179.4/29
ip nat outside
exit
interface fw-cod
ip address 192.168.1.1/24
ip nat inside 
exit 
port te1
service-instance fw-cod
encapsulation untagged 
connect ip interface fw-cod 
exit
exit
interface tunnel.0
ip address 10.10.10.1/30
ip tunnel 178.207.179.4 178.207.179.28 mode gre
ip ospf authentication message-digest 
ip ospf message-digest-key 1 md5 P@ssw0rd
exit
router ospf 1
router-id 10.10.10.1
passive-interface default
no passive-interface tunnel.0
network 10.10.10.0/30 area 0
network 192.168.1.0/24 area 0
exit
security none
aaa radius-server 10.1.10.2 port 1812 secret P@ssw0rd auth
aaa precedence local radius
router bgp 64500
bgp router-id 178.207.179.4
neighbor 178.207.179.1 remote-as 31133
exit
Ip nat pool vl100 10.1.10.1-10.1.10.254
Ip nat pool vl200 10.1.20.1-10.1.20.254
Ip nat pool vl300 10.1.30.1-10.1.30.254
Ip nat pool vl400 10.1.40.1-10.1.40.254
Ip nat pool vl500 10.1.50.1-10.1.50.254
ip nat pool fw-cod 192.168.1.1-192.168.1.10
Ip nat source dynamic inside-to-outside pool vl100 overload interface wan
Ip nat source dynamic inside-to-outside pool vl200 overload interface wan
Ip nat source dynamic inside-to-outside pool vl300 overload interface wan
Ip nat source dynamic inside-to-outside pool vl400 overload interface wan
Ip nat source dynamic inside-to-outside pool vl500 overload interface wan
Ip nat source dynamic inside-to-outside pool fw-cod overload interface wan
exit 
write memory