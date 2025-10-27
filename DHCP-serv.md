cd /etc/dhcp/dhcpd.conf - конфиг

ddns-update-style none;
authoritative; - опциаонально
subnet (СЕТЬ) netmask (МАСКА) {
        option routers                  [ШЛЮЗ];
        option subnet-mask              255.255.255.0;

        option domain-name              "domain.org";
        option domain-name-servers      [DNS];

        range dynamic-bootp [ПУЛ АДЕРСОВ];
        default-lease-time 21600;
        max-lease-time 43200;
}


cd /etc/sys