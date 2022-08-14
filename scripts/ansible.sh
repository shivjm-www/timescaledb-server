#!/bin/bash -eux
# Adapted from <https://github.com/geerlingguy/packer-boxes/blob/55412993a04d3d81ee0a61559cfd993e6d0907ad/debian11/scripts/ansible.sh>.

# Install Ansible. (The dependencies are installed in preseeding.)
pip3 install ansible
