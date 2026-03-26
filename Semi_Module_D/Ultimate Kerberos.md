Универсальный конфиг
```
cat << "EOF" > /etc/krb5.conf
[libdefaults]
        default_realm = SEMIFINAL.IRPO
        dns_lookup_realm = false
        dns_lookup_kdc = true
[realms]
SEMIFINAL.IRPO = {
        default_domain = semifinal.irpo
}
[domain_realm]
        LIN-DC1 = SEMIFINAL.IRPO
EOF