#!/bin/bash
ansible-playbook -i inventory.ini remove-open-observe.yml --ask-become-pass