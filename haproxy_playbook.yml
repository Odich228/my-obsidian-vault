---
- name: Install and configure HAProxy host
  hosts: haproxy_host
  become: true

  tasks:
    - name: Install HAProxy
      apt_rpm:
        name: haproxy
        state: present
        update_cache: true
        
    - name: Copy certificate for HAProxy
      copy:
        src: files/game.pem           <---------------------
        dest: /var/lib/ssl/game.pem
   
    - name: Copy file 'haproxy.cfg'
      copy:
        src: files/haproxy.cfg        <---------------------
        dest: /etc/haproxy/haproxy.cfg
  
    - name: Started and enabled HAProxy
      systemd:
        name: haproxy
        state: restarted
        enabled: true