```
hostnamectl set-hostname sw-cod.au.team; exec bash
useradd net_admin
passwd net_admin

usermod -aG wheel net_admin