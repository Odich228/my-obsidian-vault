```
На SRV-HQ
apt-get install -y kea-dhcp4

cat << 'EOF' > /etc/kea/kea-dhcp4.conf
{
"Dhcp4": {
  // Настройки таймеров (взял стандартные из методички)
  "valid-lifetime": 86400,
  "renew-timer": 43200,
  "rebind-timer": 75600,

  "interfaces-config": {
    // Kea сам найдет нужную сетевуху
    "interfaces": [ "ens18" ],
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

systemctl enable --now kea-dhcp4.service
