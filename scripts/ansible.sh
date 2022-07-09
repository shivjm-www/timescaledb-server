#!/bin/bash -eux
# adapted from https://github.com/geerlingguy/packer-boxes/blob/55412993a04d3d81ee0a61559cfd993e6d0907ad/debian11/scripts/ansible.sh

# Install Ansible dependencies.
apt-get -y update && apt-get -y upgrade
apt-get -y install python3-pip python3-dev

# Install Ansible.
pip3 install ansible
