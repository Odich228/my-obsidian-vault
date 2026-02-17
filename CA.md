```
#!/bin/bash

CA_DIR="/var/ca"
COUNTRY="RU"          # [cite: 83]
ORG="IRPO"            # [cite: 84]
CA_NAME="ssa2026"     # [cite: 85]
CA_EXPIRE=1825        # 5 лет 

# IP адрес srv1-cod 
SRV_IP="10.1.10.2" 

# 2. Подготовка и инициализация
mkdir -p $CA_DIR
cd $CA_DIR
easyrsa init-pki

# 3. Настройка переменных (блок без лишних пробелов)
cat <<EOF > pki/vars
set_var EASYRSA_REQ_COUNTRY    "$COUNTRY"
set_var EASYRSA_REQ_ORG        "$ORG"
set_var EASYRSA_CA_EXPIRE      $CA_EXPIRE
EOF

# 4. Создание Центра Сертификации (CA)
export EASYRSA_BATCH=1
export EASYRSA_REQ_CN="$CA_NAME"
easyrsa build-ca nopass

# 5. Выпуск сертификата для Zabbix (с учетом всех имен и IP) 
easyrsa --subject-alt-name="DNS:srv1-cod.cod.ssa2026.region,DNS:monitoring.cod.ssa2026.region,IP:$SRV_IP" \
gen-req srv1-cod.cod.ssa2026.region nopass

# 6. Подписание серверного сертификата
easyrsa sign-req server srv1-cod.cod.ssa2026.region