```
hostnamectl hostname SRV-HQ.au.team
domainname au.team

В настройка поставить адрес 10.1.1.46/28 шлюз 10.1.1.33

cat <<EOF > ~/.terraformrc
provider_installation {
    network_mirror {
        url = "https://terraform-mirror.mcs.mail.ru"
        include = ["registry.terraform.io/*/*"]
    }
    direct {
        exclude = ["registry.terraform.io/*/*"]
    }
}
EOF


mkdir /home/user/terraform
cd /home/user/terraform

cat <<EOF > terraform.tf
terraform {
  required_providers {
    freeipa = {
      source  = "camptocamp/freeipa"
      version = "1.0.0"
    }
  }
}
EOF

cat <<EOF > providers.tf
provider "freeipa" {
  host = var.freeipa_host
  username = var.freeipa_username
  password = var.freeipa_username_password
  insecure = true
}
EOF

cat <<EOF > terraform.tfvars
freeipa_host              = "srv-hq.au.team"
freeipa_username          = "admin"
freeipa_username_password = "P@ssw0rd"
EOF

cat <<EOF > variable.tf
variable "freeipa_host" {
  type = string
  description = "Хоты фриИпы"
}

variable "freeipa_username" {
  type = string
  description = "Юзы фриИпы"
}

variable "freeipa_username_password" {
  type = string 
  description = "Пароли фри ипы "
  sensitive = true
}
EOF

terraform init


tree -a

cat <<EOF >> variable.tf

variable "reverse_zones" {
  description = "List of reverse viewing zones"
  type        = list(string)
  default = [
	"1.1.10.in-addr.arpa.",
    "2.1.10.in-addr.arpa.",
    "0.2.10.in-addr.arpa.",
    "1.2.10.in-addr.arpa.",
    "2.2.10.in-addr.arpa.",
    "16.172.in-addr.arpa."
  ]
}

variable "dns_records" {
  description = "List of DNS records (A and corresponding PTR)"
  type = list(object({
    hostname            = string
    ip_address          = string
    forward_zone        = string
    reverse_zone        = optional(string)
    reverse_zone_record = optional(string)
  }))
  default = [
    {
      hostname            = "fw-hq"
      ip_address          = "10.1.1.1"
      forward_zone        = "au.team."
      reverse_zone        = "1.1.10.in-addr.arpa."
      reverse_zone_record = "1"
    },
    {
      hostname            = "adm-hq"
      ip_address          = "10.1.1.46"
      forward_zone        = "au.team."
      reverse_zone        = "1.1.10.in-addr.arpa."
      reverse_zone_record = "46"
    },
    {
      hostname            = "rtr-br"
      ip_address          = "10.2.0.1"
      forward_zone        = "au.team."
      reverse_zone        = "0.2.10.in-addr.arpa."
      reverse_zone_record = "1"
    },
    {
      hostname            = "fw-br"
      ip_address          = "10.2.0.2"
      forward_zone        = "au.team."
      reverse_zone        = "0.2.10.in-addr.arpa."
      reverse_zone_record = "2"
    },
    {
      hostname            = "srv-br"
      ip_address          = "10.2.1.10"
      forward_zone        = "au.team."
      reverse_zone        = "1.2.10.in-addr.arpa."
      reverse_zone_record = "10"
    },
    {
      hostname            = "rtr-cod"
      ip_address          = "172.16.1.254"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "254.1"
    },
    {
      hostname            = "sw-cod"
      ip_address          = "172.16.1.0"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "0.1"
    },
    {
      hostname            = "ha1-cod"
      ip_address          = "172.16.0.1"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "1.0"
    },
    {
      hostname            = "ha2-cod"
      ip_address          = "172.16.0.2"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "2.0"
    },
    {
      hostname            = "srv1-cod"
      ip_address          = "172.16.1.1"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "1.1"
    },
    {
      hostname            = "srv2-cod"
      ip_address          = "172.16.1.2"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "2.1"
    },
    {
      hostname            = "srv3-cod"
      ip_address          = "172.16.1.3"
      forward_zone        = "au.team."
      reverse_zone        = "16.172.in-addr.arpa."
      reverse_zone_record = "3.1"
    }
  ]
}
EOF

nano dns.tf


resource "freeipa_dns_zone" "reverse" {
  for_each  = toset(var.reverse_zones)
  zone_name = each.value
}

resource "freeipa_dns_record" "a" {
  for_each        = { for r in var.dns_records : r.hostname => r }
  dnszoneidnsname = each.value.forward_zone
  idnsname        = each.value.hostname
  records         = [each.value.ip_address]
  type            = "A"
}

resource "freeipa_dns_record" "ptr" {
  for_each        = { for r in var.dns_records : r.hostname => r }
  dnszoneidnsname = each.value.reverse_zone
  idnsname        = each.value.reverse_zone_record
  records         = ["${each.value.hostname}.${each.value.forward_zone}"]
  type            = "PTR"

  depends_on = [freeipa_dns_zone.reverse]
}


terraform apply -auto-approve






ANSIBLE
на руте!!!
apt-get update && apt-get install -y python3-module-pip
юзер!!!
ssh-keygen -t rsa

for i in ha1 ha2 srv1 srv2 srv3;
do ssh-copy-id root@$i-cod
done

mkdir /home/user/ansible 
cd /home/user/ansible
python3 -m venv venv/ansible
source venv/ansible/bin/activate
pip install --upgrade pip && pip install ansible
mkdir -p inventories/production

cat <<EOF > inventories/production/hosts
all:
  children:
    proxy:
      hosts:
        ha1-cod:
        ha2-cod:
    server:
      hosts:
        srv1-cod:
        srv2-cod:
        srv3-cod:
EOF

mkdir inventories/production/group_vars

cat <<EOF > inventories/production/group_vars/all.yml
---
ansible_python_interpreter: /usr/bin/python3
ansible_ssh_user: root
ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF

ansible -i inventories/production/hosts -m ping all

cat << EOF > playbook1_keepalived.yml
- name: Install and settings keepalived for HA1-COD and HA2-COD
  hosts: proxy
  become: true

  tasks:
    - name: Install package 'keepalived'
      community.general.apt_rpm:
        name: "keepalived"
        state: present
        update_cache: true

- hosts: ha1-cod
  become: true

  tasks:
    - name: Copy the 'keepalived.conf' file for MASTER
      ansible.builtin.template:
        src: templates/keepalived-master.conf.j2
        dest: /etc/keepalived/keepalived.conf
        owner: root
        group: root
        mode: '0644'

- hosts: ha2-cod
  become: true

  tasks:
    - name: Copy the 'keepalived.conf' file for BACKUP
      ansible.builtin.template:
        src: templates/keepalived-backup.conf.j2
        dest: /etc/keepalived/keepalived.conf
        owner: root
        group: root
        mode: '0644'

- hosts: proxy
  become: true

  tasks:
    - name: Started and enabled keepalived
      ansible.builtin.systemd:
        name: keepalived
        state: started
        enabled: true
EOF

mkdir templates

cat <<EOF > templates/keepalived-master.conf.j2
global_defs {
    enable_script_security
    max_auto_priority
}

vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance VI_1 {
  interface {{ keepalived_interface_name }}
  state MASTER

  virtual_router_id 51
  priority 101

  virtual_ipaddress {
    {{ keepalived_virtual_ipaddress }}
  }

  track_script {
    chk_haproxy
  }
}
EOF

cat <<EOF > templates/keepalived-backup.conf.j2
global_defs {
    enable_script_security
    max_auto_priority
}

vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance VI_1 {
  interface {{ keepalived_interface_name }}
  state BACKUP

  virtual_router_id 51
  priority 100

  virtual_ipaddress {
    {{ keepalived_virtual_ipaddress }}
  }

  track_script {
    chk_haproxy
  }
}
EOF

СМОТРИ КАК НАЗЫВАЕТСЯ ИНТЕРФЕЙС

cat <<EOF > inventories/production/group_vars/proxy.yml
keepalived_interface_name: "ens19"
keepalived_virtual_ipaddress: "172.16.1.253/23"
EOF


ansible-playbook -i inventories/production/hosts playbook1_keepalived.yml 


cat <<EOF > playbook2_web.yml
---
- name: Install Installing the Angie Web Server
  hosts: server
  become: true
  
  tasks:
    - name: Install package 'angie'
      community.general.apt_rpm:
        name: "angie"
        state: present
        update_cache: true
        
    - name: Copy the 'index.html' file
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: /usr/share/angie/html/index.html
        owner: root
        group: root
        mode: '0644'
        
    - name: Started and enabled angie
      ansible.builtin.systemd:
        name: angie
        state: started
        enabled: true
EOF


cat <<EOF > templates/index.html.j2
<html>
   <head>
      <title>AU_Team</title>
   </head>
   <body>
      <h1>{{ ansible_facts['hostname'] }} by Angie!</h1>
   </body>
</html>
EOF

ansible-playbook -i inventories/production/hosts playbook2_web.yml 

cat <<EOF > playbook3_haproxy.yml
---
- name: Install and settings haproxy for HA1-COD and HA2-COD
  hosts: proxy
  become: true

  tasks:
    - name: Install package 'haproxy'
      community.general.apt_rpm:
        name: "haproxy"
        state: present
        update_cache: true

    - name: Copy the 'haproxy.cfg' file
      ansible.builtin.template:
        src: templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        owner: root
        group: root
        mode: '0644'

    - name: Started and enabled haproxy
      ansible.builtin.systemd:
        name: haproxy
        state: started
        enabled: true
EOF

cat <<EOF > templates/haproxy.cfg.j2
global
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    daemon

defaults
    log     global
    mode    http
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

frontend main
    bind {{ haproxy_frontend_bind_address }}:{{ haproxy_frontend_bind_port }}
    default_backend             app

backend app
    balance     roundrobin
    option httpchk GET /
    http-request set-header X-Forwarded-For %[src]
    http-request set-header X-Forwarded-Proto http
{% for record in haproxy_backend_add_hosts %}
    server {{ record.name }} {{ record.address }}:80 check
{% endfor %}

listen stats
    bind *:9000
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /haproxy_stats
EOF


cat <<EOF >> inventories/production/group_vars/proxy.yml

haproxy_frontend_bind_address: "0.0.0.0"
haproxy_frontend_bind_port: "80"
haproxy_backend_add_hosts:
  - name: "srv1-cod"
    address: "172.16.1.1"
  - name: "srv2-cod"
    address: "172.16.1.2"
  - name: "srv3-cod"
    address: "172.16.1.3"
EOF

ansible-playbook -i inventories/production/hosts playbook3_haproxy.yml 