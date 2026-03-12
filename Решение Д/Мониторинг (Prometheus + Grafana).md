##### Установка prometheus-node_exporter
На хостах LIN-DC1, LIN-DC2 и LIN-SRV1
```
apt-get install prometheus-node_exporter -y
systemctl enable --now  prometheus-node_exporter
```

Добавляем в доменный DNS запись типа A - mon.semifinal.irpo 192.168.1.5
##### На хосте LIN-SRV1
Меняем DNS на доменный
```
echo -e "nameserver 192.168.1.3\nsearch semifinal.irpo" > /etc/net/ifaces/ens18/resolv.conf
systemctl restart network
```
Устанавливаем софт
```
apt-get update && apt-get install prometheus grafana -y
```
приводим конфиг к виду:

```
vim /etc/prometheus/prometheus.yml
```


```
scrape_configs:

  - job_name: 'prometheus'
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'LIN-DC1.semifinal.irpo'
    static_configs:
      - targets: ['192.168.1.3:9100']
  - job_name: 'LIN-DC2.semifinal.irpo'
    static_configs:
      - targets: ['192.168.1.2:9100']
  - job_name: 'LIN-SRV1.semifinal.irpo'
    static_configs:
      - targets: ['192.168.1.4:9100']
```
Запускаем Prometheus и Grafana
```
systemctl enable --now prometheus.service grafana-server.service
```
Смотрим статус
```
systemctl status prometheus.service grafana-server.service
```


##### На хосте ADM
Заходим в браузере по адресу http://mon.semifinal.irpo:9090, проверяем Target
Заходим в браузере по адресу http://mon.semifinal.irpo:3000,  в Grafana(admin/admin), добавляем data source http://localhost:9090, импортируем dashboard  1860
