```
---
- name: Install docker containers to games hosts
  hosts: games_hosts
  become: true
  become_user: root

  tasks:
    - name: Install docker
      apt_rpm:
        name:
          - docker-engine
          - docker-buildx
        state: present
        update_cache: true

    - name: Started and enabled docker
      systemd:
        name: docker
        state: started
        enabled: true

    - name: Copying the project files
      copy:
        src: files/2048-game/
        dest: "/home/{{ ansible_ssh_user }}/2048-game/"

    - name: Copying the Dockerfile
      copy:
        src: ./Dockerfile
        dest: "/home/{{ ansible_ssh_user }}/2048-game/"

    - name: Build docker image
      community.docker.docker_image_build:
        name: "2048-game"
        tag: latest
        path: "/home/{{ ansible_ssh_user }}/2048-game/"
        dockerfile: Dockerfile

    - name: Run container via docker CLI (no python docker sdk)
      shell: "docker run -d --name 2048-game --restart=always -p 80:80 2048-game:latest"