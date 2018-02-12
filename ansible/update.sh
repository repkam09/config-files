#!/bin/bash
ansible-playbook -i ./inventory ./playbooks/update.yaml -K
