#!/bin/bash
ansible-playbook -i inventory.ini audit.yml --ask-become-pass