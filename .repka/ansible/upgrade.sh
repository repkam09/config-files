#!/bin/bash
ansible-playbook -i inventory.ini upgrade.yml --ask-become-pass
