#### Выключай Win-DC

#### На Lin-DC1

```
samba-tool computer list --base-dn "OU=Domain Controllers"
ldbsearch -H /var/lib/samba/private/sam.ldb '(invocationId=*)' --cross-ncs objectguid | grep -A1 WIN-DC
samba-tool domain demote --remove-other-dead-server=win-dc
```