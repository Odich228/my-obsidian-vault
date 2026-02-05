разворачиваем виртваулку 
на виртуалке 
sudo apt-get update && sudo apt-get install python3-module-openstackclient python3-module-octaviaclient python3-module-neutronclient python3-module-novaclient -y



192.168.1.10 haproxy01.dev.au.team haproxy01
192.168.1.10 game.au.team game
192.168.1.11 game01.dev.au.team game01
192.168.1.12 game02.dev.au.team game02
192.168.1.13 game03.dev.au.team game03
192.168.1.21 cb.au.team cb
192.168.1.21 acm-server.au.team acm-server
192.168.1.22 db-server.au.team db-server
192.168.1.23 bar-agent01.au.team bar-agent01



apt-get update && apt-get install kernel-headers-modules-6.12 gcc make kmod-sign cpio postgresql17 postgresql17-contrib

/etc/init.d/postgresql initdb

systemctl enable --now postg