hostname cli2-a.office.ssa2026.region

apt-get install -y task-auth-ad-sssd admc gpupdate gpui

timedatectl  set-timezone Europe/Moscow

vim /etc/chrony.conf

	pool 100.100.100.100 iburst