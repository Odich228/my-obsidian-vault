#### Выключай Win-DC

#### На Lin-DC1

```
samba-tool computer list --base-dn "OU=Domain Controllers"
ldbsearch -H /var/lib/samba/private/sam.ldb '(invocationId=*)' --cross-ncs objectguid | grep -A1 WIN-DC; systemctl mask network
samba-tool domain demote --remove-other-dead-server=win-dc
```

#### Обновляем зоны DNS
```
samba-tool dns zonelist lin-dc1.semifinal.irpo -U Administrator
samba-tool dns zonecreate lin-dc1.semifinal.irpo 2.169.192.in-addr.arpa -U Administrator
```
