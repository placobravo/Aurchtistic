#!/bin/bash
# Execute some last actions before deleting itself

# Enable some systemd user services
systemctl --user enable --now pipewire-pulse pipewire wireplumber

# Remove autostart file
rm $HOME/.config/fish/conf.d/aurchtistic_temp.fish

# Runs some last actions as root, give $USER as parameter to script
doas /home/$USER/.local/cache/aurchtistic/aurchtistic_finalize_root.sh $USER

# Remove the cache directory as last action
rm -rf /home/$USER/.local/cache/aurchtistic

exit 0
