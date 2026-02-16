en

conf t

hostname rtr-a 

ip domain-name office.ssa2026.region

ip route 0.0.0.0/0 178.207.179.25

interface wan 

ip address 178.207.179.28/29

ip nat outside 

exit


interface vl100

ip address 10.2.10.1/24

ip nat inside 

exit

interface vl200

ip address 10.2.20.1/24

ip nat inside 

exit

interface vl300

ip address 10.2.30.1/24

ip nat inside

exit

port te0

service-instance wan

encapsulation untagged

connect ip interface wan

exit

exit

port te1

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

exit

Ip nat pool vl100 10.2.10.1-10.2.10.254

Ip nat pool vl200 10.2.20.1-10.2.20.254

Ip nat pool vl300 10.2.30.1-10.2.30.254

Ip nat source dynamic inside-to-outside pool vl100 overload interface wan

Ip nat source dynamic inside-to-outside pool vl200 overload interface wan

Ip nat source dynamic inside-to-outside pool vl300 overload interface wan

interface tunnel.0

ip address 10.10.10.2/30

ip tunnel 178.207.179.28 178.207.179.4 mode gre

ip ospf authentication message-digest

ip ospf message-digest-key 1 md5 P@ssw0rd

exit

router ospf 1

router-id 10.10.10.2

passive-interface default

no passive-interface tunnel.0

network 10.10.10.0/30 area 0

network 10.2.10.0/24 area 0

network 10.2.20.0/24 area 0

network 10.2.30.0/24 area 0

exit

ntp timezone utc+3

ntp server 100.100.100.100

write memory