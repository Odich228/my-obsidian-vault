 /etc/dhcp/dhcpd.conf - конфиг

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


/etc/sysconfig/dhcpd - порт 

 The following variables are recognized:

DHCPDARGS="ens18" - вот здесь

#Default value if chroot mode disabled.
#CHROOT="-j / -lf /var/lib/dhcp/dhcpd/state/dhcpd.leases"

