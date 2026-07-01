#!/bin/bash
ansible-playbook -i inventory.ini unattended-upgrades.yml --ask-become-pass
