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

cat <<EOF > variable.rf
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

cat <<EOF >> variable.tf

variable "reverse_zones" {
  description = "List of reverse viewing zones"
  type        = list(string)
  default = [
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

cat <<EOF > dns.tf
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
EOF

terraform apply -auto-approve






ANSIBLE
apt-get update && apt-get install -y python3-module-pip
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
