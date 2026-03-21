```
hostnamectl set-hostname srv-br.au.team; exec bash

echo "TYPE=eth" > /etc/net/ifaces/enp6s18/options
echo "10.2.1.10/28" > /etc/net/ifaces/enp6s18/ipv4address
echo "default via 10.2.1.14" > /etc/net/ifaces/enp6s18/ipv4route
echo "search au.team" > /etc/net/ifaces/enp6s18/resolv.conf
echo "nameserver 10.1.1.10" >> /etc/net/ifaces/enp6s18/resolv.conf
systemctl restart network

apt-get update && apt-get install -y apache2 apache2-mod_ssl apache2-mod_php8.4 php8.4 php8.4-{pgsql,pdo_pgsql,curl,dom,exif,fileinfo,gd2,gmp,imagick,intl,libs,mbstring,memcached,opcache,openssl,pcntl,pdo,xmlreader,zip,ldap}

for i in dir env headers mime rewrite;do a2enmod $i;done

systemctl enable --now httpd2

wget https://download.nextcloud.com/server/releases/nextcloud-33.0.0.zip

cp -r nextcloud /var/www/html/ && rm -rf nextcloud

chown -R root /var/www/html/nextcloud
mkdir /var/www/html/nextcloud/data
chown -R apache2 /var/www/html/nextcloud/{apps,config,data}/

cat <<EOF > /etc/httpd2/conf/sites-available/nextcloud.conf
<VirtualHost *:80>
  DocumentRoot /var/www/html/nextcloud/

  <Directory /var/www/html/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
EOF

ln -s /etc/httpd2/conf/sites-available/nextcloud.conf /etc/httpd2/conf/sites-enabled/
systemctl restart httpd2

apt-get install -y postgresql17-server

/etc/init.d/postgresql initdb

systemctl enable --now postgresql

su - postgres -s /bin/bash -c 'createuser --no-superuser --no-createdb --no-createrole --encrypted --pwprompt nextclouduser'

su - postgres -s /bin/bash -c 'createdb -O nextclouduser nextclouddb'