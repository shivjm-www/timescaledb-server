#!/bin/bash -eux
# Adapted from <https://github.com/geerlingguy/packer-boxes/blob/55412993a04d3d81ee0a61559cfd993e6d0907ad/debian11/scripts/cleanup.sh>.

# Add cloud-init for DigitalOcean.
apt-get install -y cloud-init

# Uninstall Ansible and dependencies.
pip3 uninstall ansible
apt-get remove python3-pip python3-dev

# Apt cleanup.
apt-get autoremove -y

#  Blank netplan machine-id (DUID) so machines get unique ID generated on boot.
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Delete unneeded files.
rm -f ~/*.sh
rm -f /tmp/*.{tar,gz,bz2,zip}

# Zero out the rest of the free space using dd, then delete the written file.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

systemctl enable fstrim.timer --now
