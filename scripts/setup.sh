#!/bin/bash
set -euxo pipefail

# Add user to sudoers.
echo "$USERNAME        ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
