#!/bin/bash
# Execute some last actions before deleting itself

# Enable some systemd user services
systemctl --user enable --now pipewire-pulse pipewire wireplumber

# Remove the last line that lets this script runs after zsh login
sed -i -e '$d' $HOME/.zprofile

# Runs some last actions as root, give $USER as parameter to script
doas /home/$USER/.local/cache/aurchtistic/aurchtistic_finalize_root.sh $USER

# Remove the cache directory as last action
rm -rf /home/$USER/.local/cache/aurchtistic

exit 0
