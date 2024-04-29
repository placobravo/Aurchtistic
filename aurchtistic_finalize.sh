#!/bin/bash
# Execute some last actions before deleting itself

# Enable some systemd user services
systemctl --user enable --now pipewire-pulse pipewire wireplumber

# Remove the line that lets this script runs after zsh login
sed -i -e '$d' $HOME/.zprofile

# Runs some last actions as root, give $USER as parameter to script
doas $HOME/.local/bin/aurchtistic_finalize_root.sh $USER

# Remove the two scripts as final action
rm $HOME/.local/bin/aurchtistic_finalize.sh
rm $HOME/.local/bin/aurchtistic_finalize_root.sh

exit 0
