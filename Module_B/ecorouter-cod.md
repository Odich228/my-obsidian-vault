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
interface vl100 
ip address 10.1.10.1/24
ip nat inside
exit
interface vl200 
ip address 10.1.20.1/24
ip nat inside
exit
interface vl300 
ip address 10.1.30.1/24
ip nat inside
exit
interface vl400 
ip address 10.1.40.1/24
ip nat inside
exit
interface vl500 
ip address 10.1.50.1/24
ip nat inside
exit
port te0
service-instance wan
encapsulation untagged 
connect ip interface wan
exit
exit
port te1
service-instance fw-cod
encapsulation untagged 
connect ip interface fw-cod 
exit
service-instance vl100
encapsulation dot1q 100
rewrite pop 1
connect ip interface vl100 
exit
service-instance vl200
encapsulation dot1q 200
rewrite pop 1
connect ip interface vl200 
exit
service-instance vl300
encapsulation dot1q 300
rewrite pop 1
connect ip interface vl300 
exit
service-instance vl400
encapsulation dot1q 400
rewrite pop 1
connect ip interface vl400 
exit
service-instance vl500
encapsulation dot1q 500
rewrite pop 1
connect ip interface vl500 
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
Ip nat source dynamic inside-to-outside pool vl100 overload interface wan
Ip nat source dynamic inside-to-outside pool vl200 overload interface wan
Ip nat source dynamic inside-to-outside pool vl300 overload interface wan
Ip nat source dynamic inside-to-outside pool vl400 overload interface wan
Ip nat source dynamic inside-to-outside pool vl500 overload interface wan
exit 
write memory