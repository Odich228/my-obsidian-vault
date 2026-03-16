terraform {
  required_providers {
    freeipa = {
      source  = "camptocamp/freeipa"
      version = "1.0.0"
    }
  }
}

provider "freeipa" {
  host     = "srv-hq.au.team"
  username = "admin"
  password = "P@ssw0rd"
  insecure = true
}

# --- 1. Обратные зоны (Reverse Zones) ---
# На основе переменной reverse_zones

resource "freeipa_dns_zone" "rev_2_1_10" {
  zone_name = "2.1.10.in-addr.arpa."
}

resource "freeipa_dns_zone" "rev_0_2_10" {
  zone_name = "0.2.10.in-addr.arpa."
}

resource "freeipa_dns_zone" "rev_1_2_10" {
  zone_name = "1.2.10.in-addr.arpa."
}

resource "freeipa_dns_zone" "rev_2_2_10" {
  zone_name = "2.2.10.in-addr.arpa."
}

resource "freeipa_dns_zone" "rev_16_172" {
  zone_name = "16.172.in-addr.arpa."
}

# --- 2. Прямые записи (A Records) ---
# На основе списка dns_records

resource "freeipa_dns_record" "a_fw_hq" {
  dnszoneidnsname = "au.team."
  idnsname        = "fw-hq"
  records         = ["10.1.1.1"]
  type            = "A"
}

resource "freeipa_dns_record" "a_adm_hq" {
  dnszoneidnsname = "au.team."
  idnsname        = "adm-hq"
  records         = ["10.1.1.46"]
  type            = "A"
}

resource "freeipa_dns_record" "a_rtr_br" {
  dnszoneidnsname = "au.team."
  idnsname        = "rtr-br"
  records         = ["10.2.0.1"]
  type            = "A"
}

resource "freeipa_dns_record" "a_fw_br" {
  dnszoneidnsname = "au.team."
  idnsname        = "fw-br"
  records         = ["10.2.0.2"]
  type            = "A"
}

resource "freeipa_dns_record" "a_srv_br" {
  dnszoneidnsname = "au.team."
  idnsname        = "srv-br"
  records         = ["10.2.1.10"]
  type            = "A"
}

resource "freeipa_dns_record" "a_rtr_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "rtr-cod"
  records         = ["172.16.1.254"]
  type            = "A"
}

resource "freeipa_dns_record" "a_sw_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "sw-cod"
  records         = ["172.16.1.0"]
  type            = "A"
}

resource "freeipa_dns_record" "a_ha1_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "ha1-cod"
  records         = ["172.16.0.1"]
  type            = "A"
}

resource "freeipa_dns_record" "a_ha2_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "ha2-cod"
  records         = ["172.16.0.2"]
  type            = "A"
}

resource "freeipa_dns_record" "a_srv1_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "srv1-cod"
  records         = ["172.16.1.1"]
  type            = "A"
}

resource "freeipa_dns_record" "a_srv2_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "srv2-cod"
  records         = ["172.16.1.2"]
  type            = "A"
}

resource "freeipa_dns_record" "a_srv3_cod" {
  dnszoneidnsname = "au.team."
  idnsname        = "srv3-cod"
  records         = ["172.16.1.3"]
  type            = "A"
}

# --- 3. Обратные записи (PTR Records) ---

resource "freeipa_dns_record" "ptr_fw_hq" {
  dnszoneidnsname = "1.1.10.in-addr.arpa."
  idnsname        = "1"
  records         = ["fw-hq.au.team."]
  type            = "PTR"
}

resource "freeipa_dns_record" "ptr_adm_hq" {
  dnszoneidnsname = "1.1.10.in-addr.arpa."
  idnsname        = "46"
  records         = ["adm-hq.au.team."]
  type            = "PTR"
}

resource "freeipa_dns_record" "ptr_rtr_br" {
  dnszoneidnsname = "0.2.10.in-addr.arpa."
  idnsname        = "1"
  records         = ["rtr-br.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_0_2_10]
}

resource "freeipa_dns_record" "ptr_fw_br" {
  dnszoneidnsname = "0.2.10.in-addr.arpa."
  idnsname        = "2"
  records         = ["fw-br.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_0_2_10]
}

resource "freeipa_dns_record" "ptr_srv_br" {
  dnszoneidnsname = "1.2.10.in-addr.arpa."
  idnsname        = "10"
  records         = ["srv-br.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_1_2_10]
}

resource "freeipa_dns_record" "ptr_rtr_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "254.1"
  records         = ["rtr-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}

resource "freeipa_dns_record" "ptr_sw_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "0.1"
  records         = ["sw-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}

resource "freeipa_dns_record" "ptr_ha1_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "1.0"
  records         = ["ha1-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}

resource "freeipa_dns_record" "ptr_ha2_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "2.0"
  records         = ["ha2-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}

resource "freeipa_dns_record" "ptr_srv1_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "1.1"
  records         = ["srv1-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}

resource "freeipa_dns_record" "ptr_srv2_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "2.1"
  records         = ["srv2-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}

resource "freeipa_dns_record" "ptr_srv3_cod" {
  dnszoneidnsname = "16.172.in-addr.arpa."
  idnsname        = "3.1"
  records         = ["srv3-cod.au.team."]
  type            = "PTR"
  depends_on      = [freeipa_dns_zone.rev_16_172]
}