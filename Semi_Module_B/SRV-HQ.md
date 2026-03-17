```
hostnamectl set-hostname srv-hq.au.team; exec bash
sed -i "s/HOSTNAME=localhost/HOSTNAME=srv-hq.au.team/g" /etc/sysconfig/network

echo "TYPE=eth" > /etc/net/ifaces/enp6s18/options
echo "10.1.1.10/27" > /etc/net/ifaces/enp6s18/ipv4address
echo "default via 10.1.1.1" > /etc/net/ifaces/enp6s18/ipv4route
echo "search au.team" > /etc/net/ifaces/enp6s18/resolv.conf
echo "nameserver 77.88.8.8" >> /etc/net/ifaces/enp6s18/resolv.conf
systemctl restart network
apt-get update && apt-get install -y haveged freeipa-server-dns
systemctl enable --now haveged
echo "10.1.1.10 srv-hq.au.team srv-hq" > /etc/hosts
ipa-server-install 
	1.-
	2.-
	3.-
	4.P@ssw0rd
	5.yes
	6.-
	7.-
	8.77.88.8.8
	9.-
	10.yes
	11.-
	12.-
	13.-
	14.yes
	15.-
	16.-
	17.yes
ipactl status  (ПРОВЕРКА)
echo "allow-query { any; };" >> /etc/bind/ipa-options-ext.conf
ipactl restart
echo "P@ssw0rd" | kinit admin@AU.TEAM
ipa role-add "CIFS server" --desc="Role for CIFS server"
ipa role-add "Organization units" --desc="Role for Organization units"

reboot

echo "P@ssw0rd" | kinit admin

ipa group-add hq
ipa group-add br
ipa group-add cod

for i in {1..5}; do
echo "P@ssw0rd" | ipa user-add hq.user$i --first=hq --last=user$i --password
echo "P@ssw0rd" | ipa user-add br.user$i --first=br --last=user$i --password
echo "P@ssw0rd" | ipa user-add cod.user$i --first=cod --last=user$i --password
done

for i in {1..5}; do
ipa group-add-member hq --users=hq.user$i
ipa group-add-member br --users=br.user$i
ipa group-add-member cod --users=cod.user$i
done


cat << 'EOF' > /etc/kea/kea-dhcp4.conf
{
"Dhcp4": {
  // Настройки таймеров (взял стандартные из методички)
  "valid-lifetime": 86400,
  "renew-timer": 43200,
  "rebind-timer": 75600,

  "interfaces-config": {
    // Kea сам найдет нужную сетевуху
    "interfaces": [ "*" ],
    "dhcp-socket-type": "raw"
  },

  "control-socket": {
    "socket-type": "unix",
    "socket-name": "/run/kea/kea4-ctrl-socket"
  },

  "lease-database": {
    "type": "memfile",
    "name": "/var/lib/kea/kea-leases4.csv", 
    "lfc-interval": 600
  },

  "subnet4": [
    {
      "id": 150,
      "subnet": "10.1.2.0/24",
      "pools": [
        {
          "pool": "10.1.2.128 - 10.1.2.254"
        }
      ],
      "option-data": [
        {
          "name": "routers",
          "data": "10.1.2.1"
        },
        {
          "name": "domain-name-servers",
          "data": "10.1.1.10"
        },
        {
          "name": "domain-name",
          "data": "au.team"
        },
        {
          "name": "domain-search",
          "data": "au.team"
        }
      ]
    }
  ]
}
}
EOF