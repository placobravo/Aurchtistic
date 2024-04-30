#!/bin/bash
# Execute some last actions before deleting itself

# Enable some systemd user services
systemctl --user enable --now pipewire-pulse pipewire wireplumber

# Remove the last two lines that let this script runs after zsh login
sed -i -e '$d' $HOME/.zprofile
sed -i -e '$d' $HOME/.zprofile

# Runs some last actions as root, give $USER as parameter to script
doas ${CACHE_DIR}/aurchtistic_finalize_root.sh $USER

# Remove the two scripts as final action
rm ${CACHE_DIR}/aurchtistic_finalize.sh
rm ${CACHE_DIR}/aurchtistic_finalize_root.sh

exit 0
