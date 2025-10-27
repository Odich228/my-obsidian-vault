 /etc/bind/local.conf - описывать зоны 
 include "/etc/bind/rfc1912.conf";

// Consider adding the 1918 zones here,
// if they are not used in your organization.
//      include "/etc/bind/rfc1918.conf";

// Add other zones here
zone "name" {
	type master;
	file "/etc/bind/zone/''name file"";
}
----------------------------------------------------------------------------------

/etc/bind/zone/ - здесь файлы зоны 

"name file zone" :

$TTL    1D  
@       IN      SOA     localhost. root.localhost. (  
                               2025020600      ; serial  
                               12H             ; refresh  
                               1H              ; retry  
                               1W              ; expire  
                               1H              ; ncache  
                       )  
       IN      NS      localhost.  
       IN      A       127.0.0.1
