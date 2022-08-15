#!/usr/bin/bash

set -euxo pipefail

ISO_DIR=/media/iso
apt-get install -y build-essential dkms linux-headers-$(uname -r)
mkdir -p /media/iso
mount $ISO_PATH $ISO_DIR -o loop
sh $ISO_DIR/VBoxLinuxAdditions.run --nox11
umount $ISO_DIR
