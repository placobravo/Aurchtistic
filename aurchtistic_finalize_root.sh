#!/bin/bash
# Execute some last actions as root user, before being deleted by aurchtistic_finalize.sh

# Enable ufw firewall and apply rules
ufw default deny incoming
ufw allow 22
ufw enable

# Modify /etc/doas.conf
sed -i -e "/permit nopass $1 as root/d" /etc/doas.conf
sed -i -e "/permit nopass root as $1/d" /etc/doas.conf
chmod -c 0400 /etc/doas.conf

# Make zsh default shell
chsh -s /bin/zsh

exit 0
