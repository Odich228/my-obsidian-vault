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
