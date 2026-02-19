#!/bin/bash

export PATH=/home/altlinux/.local/bin:$PATH <---------------------

cd /home/$USER/Projects/Project_01/ansible  <---------------------

ansible-playbook game_playbook.yml
sleep 20
ansible-playbook haproxy_playbook.yml