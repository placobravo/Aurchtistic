#!/bin/bash

username="tonio"
CACHE_DIR="/home/$username/.local/cache/aurchtistic"
aurchtistic_repo="https://github.com/placobravo/Aurchtistic"
dotfiles="https://github.com/placobravo/arch-configs"
VERBOSE=1
SKIP=0
AURHELPER="paru"

verbose() {
	# Function used to either be silent or verbose depending on flags

	if [ "$VERBOSE" -eq 1 ]; then
		"$@"
	else
		"$@" >/dev/null 2>&1
	fi
}


typer() {
	# Function used to make printing of text a little fancier,
	# as it being typed in real time

	local speed=0.025

	while getopts "s:" flag; do
		case $flag in
		s)
			speed="${OPTARG}"
			;;
		esac
	done

	shift $(($OPTIND - 1))
	local string=$1
	# We use parameter expansions and print each letter of string, but
	# we feed two consecutive letters at the same time if we have a '\'
	# symbol, because in that case we want echo/printf to interpret the
	# two symbols togheter
	for ((i = 0; i < ${#string}; i++)); do
		if [ "${string:$i:1}" = '\' ]; then
			printf "${string:$i:1}${string:$((i + 1)):1}"
			((i++))
		else
			printf "${string:$i:1}"
		fi
		sleep "$speed"
	done
	unset OPTIND flag
}

sway_setup() {
	# Function used to configure the Desktop environment

	# Create home directories
	cd "/home/$username"
	mkdir "/home/$username/Stuff" "/home/$username/Downloads" "/home/$username/Desktop"

	# Install config files
	verbose git clone --depth=1 "$dotfiles" "/home/$username/temp_confs" || return 40
	mv /home/$username/temp_confs/* /home/$username
	mv /home/$username/temp_confs/.local/bin/ /home/$username/.local
	mv /home/$username/temp_confs/.* /home/$username 2>/dev/null
	rm -rf /home/$username/temp_confs/
	typer "Configs installed, home directories created.\n" || return 1

	# Set aurchtistic_finalize script and let it start in .zprofile
	echo "bash ${CACHE_DIR}/aurchtistic_finalize.sh" >>"/home/$username/.zprofile"
	typer "Configured aurchtistic_finalize script to run after login.\n" || return 1

	# Make sure the $username has rights for all their files
	verbose chown -R "$username:$username" "/home/$username"
	verbose chmod -R u+x "/home/$username/.local/bin/"
	verbose chmod -R u+rwx "${CACHE_DIR}"
	typer "Changed home files ownership.\n" || return 1

	# Enable required systemd services
	verbose systemctl enable NetworkManager bluetooth libvirtd udisks2 ufw sshd || return 46

	typer "Enabled systemd services.\n" || return 1
}

sway_setup

echo done
