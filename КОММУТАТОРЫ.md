( **Создаём OVS-мост `br0`**)
ovs-vsctl add-br br0

(**Подключаем порты**)
ovs-vsctl add-port br0 enp1s0 \
  tag=300 \
  vlan_mode=native-untagged \
  trunks=100,200

### Порт к `dc-a` (`enp4s0`) — **access VLAN 100**:
ovs-vsctl add-port br0 enp7s4 tag=100

### Агрегация к `sw2-a` — **active-backup** (2 порта → 1 логический):
ovs-vsctl add-bond br0 bond0 enp2s0 enp3s0 \
  bond_mode=active-backup \
  lacp=off \
  other_config:bond-arp-enable=true \
  other_config:bond-arp-ip-target=192.168.33.83

И добавим тот же trunk-режим к `bond0`
ovs-vsctl set Port bond0 \
  tag=300 \
  vlan_mode=native-untagged \
  trunks=100,200


Шаг 3. Присваиваем `sw1-a` IP-адрес для управления

ovs-vsctl add-port br0 mgmt0 -- set Interface mgmt0 type=internal
ovs-vsctl set Port mgmt0 tag=300
ip addr add 192.168.33.82/29 dev mgmt0
 ip link set mgmt0 up

## **Настройка STP (RSTP, 802.1w)**

ovs-vsctl set Bridge br0 stp_enable=true
ovs-vsctl set Bridge br0 other_config:stp-priority=4096

Поднимаем порты
 ip link set enp1s0 up
 ip link set enp2s0 up
 ip link set enp3s0 up
 ip link set enp4s0 up

## **Проверка**

ovs-vsctl show

ping -c 3 192.168.33.81

ovs-appctl bridge/dump-flows br0 | grep -i stp