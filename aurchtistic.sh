#!/bin/bash

# VARIABLES LIST
# $pass1
# $pass2
# $username
# $cache_dir
# $AURHELPER
# $packages_list
# $configs_repo
# $scripts_repo
# $VERBOSE
# $SKIP
# $dotfiles
# $aurchtistic_repo

aurchtistic_repo="https://github.com/placobravo/Aurchtistic"
dotfiles="https://github.com/placobravo/arch-configs"
VERBOSE=0
SKIP=0
AURHELPER="paru"

#################################################################################
#                                  FUNCTIONS                                    #
#################################################################################
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

show_help() {
	echo "Usage: aurchtistic.sh [OPTIONS]"
	echo "Options:"
	echo "  -h, --help      Display this help message"
	echo "  -V, --version   Display aurchtistic version"
	echo "  -v, --verbose   Display extra text output"
	echo "  -s, --packages  Display a list of the packages that will be installed"
	echo "  --skip          Skip packages configuration and do not install any optional package"
}

show_packages() {
	# Function used to show the user the packages that will be installed

	typer ciao
}

flags() {
	while getopts "vVhs-:" flag; do
		case "${flag}" in
		v)
			VERBOSE=1
			;;
		V)
			printf "%s\n" "Aurchtistic 0.1" "Don't give a f**k license."
			exit 0
			;;
		h)
			show_help
			exit 0
			;;
		s)
			show_packages
			exit 0
			;;
		-)
			case "${OPTARG}" in
			verbose)
				VERBOSE=1
				;;
			version)
				printf "%s\n" "Aurchtistic 0.1" "Don't give a f**k license."
				exit 0
				;;
			"skip")
				SKIP=1
				;;
			"packages")
				show_packages
				exit 0
				;;
			help)
				show_help
				exit 0
				;;
			esac
			;;
		esac
	done
	unset flag OPTIND
}

verbose() {
	# Function used to either be silent or verbose depending on flags

	if [ "$VERBOSE" -eq 1 ]; then
		"$@"
	else
		"$@" >/dev/null 2>&1
	fi
}

error() {
	# Function used to log errors to stout
	# Check for return status and give default output
	# {8..63} for return codes

	case "$?" in
	40)
		typer "\nYou got an error while using git.\n" >&2
		;;
	41)
		typer "\nYou got an error while fetching a file with curl.\n" >&2
		;;
	42)
		typer "\nA configuration file could not be found while running the script.\n" >&2
		;;
	43)
		typer "\nYou got an error while using pacman.\n" >&2
		;;
	44)
		typer "\nYou got an error while using $AURHELPER.\n" >&2
		;;
	45)
		typer "\nYou got an error while using flatpak.\n" >&2
		;;
	46)
		typer "\nYou got an error while using systemctl.\n" >&2
		;;
	47)
		typer "\nYou got an error while manually installing a package.\n" >&2
		;;
	48)
		typer "\nYou got an error while syncing pacman packages.\n" >&2
		;;
	esac

	# Also print some extra string if specified
	typer "$1" >&2
	exit 1
}

welcome() {
	typer -s 0.002 '
 _    _      _                            _
| |  | |    | |                          | |
| |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___
| |/\| |/ _ \ |/ __/ _ \| |_ ` _ \ / _ \ | __/ _ \
\  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) |
 \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/


  ___                 _     _   _     _   _      _
 / _ \               | |   | | (_)   | | (_)    | |
/ /_\ \_   _ _ __ ___| |__ | |_ _ ___| |_ _  ___| |
|  _  | | | | |__/ __| |_ \| __| / __| __| |/ __| |
| | | | |_| | | | (__| | | | |_| \__ \ |_| | (__|_|
\_| |_/\__,_|_|  \___|_| |_|\__|_|___/\__|_|\___(_)' || return 1

	# Check if user is root, exit otherwise
	if [ $(whoami) != "root" ]; then
		typer "\nAre you sure you are running this script as root?\n" && exit 126
	fi

	# Check if system is running arch, exit otherwise
	if ! cat /etc/os-release | grep "ID=arch" >/dev/null 2>&1; then
		typer "\nAre you sure you are running this script on an Archlinux system?\n" && exit 1
	fi

	# Check if script is running in bash, exit otherwise
	local SCRIPT_SHELL=$(ps -p $$ -o cmd | tail -n 1 | sed 's/ .*//')
	if [ ${SCRIPT_SHELL} != "bash" -a ${SCRIPT_SHELL} != "/bin/bash" ]; then
		typer "\nAre you sure you are runnig this script with bash?\n" && exit 1
	fi

	# Check dependencies
	dependencies=(git pacman-contrib)
	if ! pacman -Qq ${dependencies[@]} >/dev/null 2>&1; then
		typer "\nYou are missing some dependencies:\n\n"
		for x in ${dependencies[@]}; do
			if ! pacman -Qq | grep $x >/dev/null; then
				typer "${x}\n"
			fi
		done
		typer "\nInstall them and then run the script again.\n"
		exit 1
	fi

	typer "\n\nThis script is going to install the configuration that I use on my main Archlinux system.\n\nWARNING: Aurchtistic is assuming that you are using a brand new installation of Arch without any modification.\nSome checks are done but it is not guaranteed that the script will run correctly if you have made some changes.\n" || return 1

	typer "\nIf you start the script it is important not to stop it until it is done, in order to avoid any corruption that might happen to your system.\n" || return 1

	typer "\nIf you want to check which changes are being made to the system quit now and check the help menu.\n" || return 1

	while true; do
		read -p "Do you want to continue? (y/N): " choice
		case $choice in
		y | Y | yes | Yes | YES)
			clear
			typer "Ok, let's get this started!\n" && unset choice && break
			;;
		n | N | no | NO | No)
			typer -s 0.08 "\nOk, quitting... :(\n" && exit 0
			;;
		*)
			echo "Please type either yes or no!"
			;;
		esac
	done
}

adduserpass() {
	while true; do
		typer "Insert a username: " && read username
		useradd -m "$username" -s /bin/fish 2>/dev/null && mkdir -p /home/"$username" && usermod -aG wheel "$username" && break
		typer "\nThis username is either not valid or exists already, try again.\n"
	done
	typer "User $username added!\n" || return 1

	while true; do
		typer "Insert password: "
		read -s pass1
		typer "\nRetype your password: "
		read -s pass2
		[ "$pass1" = "$pass2" ] && break
		typer "\nPasswords do not match, please type them again.\n" || return 1
		unset pass1 pass2
	done

	echo "$username:$pass1" | chpasswd
	typer "\nPassword for $username updated!\n" || return 1

	unset pass1 pass2

	CACHE_DIR="/home/$username/.local/cache/aurchtistic"
	mkdir -p $CACHE_DIR
	chown "${username}:${username}" -R "/home/$username/"
	
	verbose git clone --depth=1 "${aurchtistic_repo}" "${CACHE_DIR}"

	typer "Preparations for script completed.\n" || return 1
}

aurhelper_install() {
	# Used to install $AURHELPER. Could also be used for other aur
	# packages but there's not need for it

	# If $AURHELPER is installed already, skip installation
	pacman -Qq $AURHELPER >/dev/null 2>&1 && echo "$AURHELPER is already installed. Skipping..." && return 0

	typer "Installing ${AURHELPER}...\n" || return 1
	cd /home/$username/
	verbose doas -u "$username" git clone "https://aur.archlinux.org/$AURHELPER.git" || return 40
	cd $AURHELPER
	verbose doas -u "$username" makepkg --noconfirm -sirc || return 47
	typer "Installation of $AURHELPER completed.\n" || return 1
}

aurchtistic_finalize() {
	# Set aurchtistic_finalize script and let it start in fish shell
	# These are actions that need to be run after a reboot

	# Execute some last actions before deleting itself
	cat << "EOF" >/home/$username/.config/fish/conf.d/aurchtistic_temp.fish
	#!/bin/bash

	# Enable some systemd user services
	systemctl --user enable --now pipewire-pulse pipewire wireplumber

	# Runs some last actions as root
	doas chmod +x /home/$USER/.local/cache/aurchtistic/aurchtistic_finalize_root.sh
	doas /home/$USER/.local/cache/aurchtistic/aurchtistic_finalize_root.sh $USER

	# Remove the cache directory as last action
	rm -rf /home/$USER/.local/cache/aurchtistic

	# Remove bash leftovers
	rm -f /home/$USER/.bash*

	# Delete itself
	rm -f $HOME/.config/fish/conf.d/aurchtistic_temp.fish

	exit 0
EOF

	# Create file with last actions to run as root after a reboot
	# Execute some last actions as root user, before being deleted by aurchtistic_temp.fish
	# The file is called by the fish function above
	cat << "EOF" >/home/$username/.local/cache/aurchtistic/aurchtistic_finalize_root.sh
	#!/bin/bash

	# Enable ufw firewall and apply rules
	ufw default deny incoming
	ufw allow 22
	ufw enable

	# Modify /etc/doas.conf
	sed -i -e "/permit nopass $1 as root/d" /etc/doas.conf
	sed -i -e "/permit nopass root as $1/d" /etc/doas.conf
	chmod -c 0400 /etc/doas.conf

	exit 0
EOF

	typer "Configured aurchtistic_finalize script to run after login.\n" || return 1
}

configure_packages() {
	# This function downloads and modifies the packages.csv list based on user options

	# Make a copy of the orignal packages file on tmp, and work on that one
	cd $CACHE_DIR
	cp packages.csv /tmp/pkgs.csv

	# If user selected the "skip" option we end the function here, and simply leave all the
	# optional packages with "O" tag in the packages.csv as they were
	[ $SKIP -eq 1 ] && return 0

	# Take packages.csv and make an array with packages name and descriptions, only for "O" tags
	pkg_array=()
	while IFS="," read -r package description; do
		pkg_array+=("$package" "$description" OFF)
	done < <(tail -n +2 packages.csv | sed -e '/O/!d' -e 's/[^,]*,//')

	# While loop to make sure the user prompted for the corrected optional packages
	while true; do

		# Take whiptail checklist and feed it to while/read cycle. For each read instance we feed
		# it to sed and modify the packages.csv file accordingly by removing the "O" tag
		while IFS= read -r line; do
			sed -i -e "s/OA,$line/A,$line/g" -e "s/OP,$line/P,$line/g" -e "s/OF,$line/F,$line/g" /tmp/pkgs.csv
		done < <(whiptail --nocancel --title "Choose optional packages" --checklist --separate-output "Select packages with space bar" $(stty size) 20 "${pkg_array[@]}" 3>&1 1>&2 2>&3 3>&1)

		# Show the user the packages they selected. We do this by using diff on the original file
		# and the current one (and some sed witchery)
		whiptail --title "Confirm your choice" --yes-button "Ok!" \
			--no-button "Choose again!" \
			--yesno "You selected these packages:\n$(diff /tmp/pkgs.csv packages.csv | sed -e '/<.*/!d' -e 's/[^,]*,//' -e 's/,.*//')" $(stty size) && break
	done

	clear
}

install_packages() {
	# Function to be used after the packages.csv list is being modified by configure_packages()

	# Modify pacman configuration file
	sed -i -e 's/#Color/Color/;s/#ParallelDownloads/ParallelDownloads/;/ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf || return 42
	typer "Modified pacman.conf with fancy effects.\n" || return 1

	# Fetch 6 best mirrors and update mirrorlist based on speed
	typer "Fetching mirrors and ranking...\n" || return 1
	curl -Lsk "https://archlinux.org/mirrorlist/?country=FR&country=SE&country=GB&country=ES&country=IT&country=DE&country=AU&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 12 - >/etc/pacman.d/mirrorlist || return 41

	# Sync packages database and update system
	typer "Syncing mirrors and packages keyring...\n" || return 1
	verbose pacman -Sy --needed --noconfirm archlinux-keyring && verbose pacman --noconfirm -Su || return 48
	verbose pacman --noconfirm -Syyu || return 48

	# Remove base-devel and reinstall its meta packages except sudo (we use opendoas)
	pacman -Qq base-devel >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		verbose pacman --noconfirm -Rs base-devel || return 43
	fi
	typer "Installing opendoas instead of sudo...\n" || return 1
	verbose pacman -S --needed --noconfirm opendoas curl debugedit autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make patch pkgconf sed texinfo which || return 43

	printf "permit :wheel\npermit nopass $username as root\npermit nopass root as $username\n" >>/etc/doas.conf || return 42
	verbose chown -c root:root /etc/doas.conf
	ln -s /usr/bin/doas /usr/bin/sudo

	# Let makepkg use doas instead of sudo
	sed -i -e 's/#PACMAN_AUTH=()/PACMAN_AUTH=(doas)/' /etc/makepkg.conf
	typer "Changed makepkg.conf to use doas.\n"

	# Replace iptables with iptables-nft
	yes | verbose pacman -S iptables-nft || return 43
	typer "Replaced iptables with nftables.\n" || return 1

	# Install $AURHELPER
    aurhelper_install || error "\nSomething went wrong while installing $AURHELPER. You can try installing it yourself, or use another AUR helper.\n"

	# Let paru use doas (if paru is used as aurhelper)
	if [ $AURHELPER = "paru" ]; then
		sed -i -e 's/#Sudo/Sudo/' /etc/paru.conf
		sed -i -e 's/#\[bin\]/[bin]/' /etc/paru.conf
		sed -i -e 's/SudoLoop/SudoLoop=true/' /etc/paru.conf
		typer "Updated paru.conf with doas.\n"
	fi

	# Install packages from pkgs.csv with P, F and A tags. Ignores packages with O tags.
	# Add each name to an array and feed all elements to package manager
	officials=()
	aurs=()
	flatpaks=()

	while IFS=, read -r tag name description; do
		case "$tag" in
		"P")
			officials+=("$name")
			;;
		"A")
			aurs+=("$name")
			;;
		"F")
			flatpaks+=("$name")
			;;
		esac
	done </tmp/pkgs.csv

	typer "Installing packages from official repos...\n" || return 1
	verbose pacman --needed -S --noconfirm "${officials[@]}" || return 43

	# If arrays are empty do not do anything
	if [ ! ${#aurs[@]} -eq 0 ]; then
		typer "Installing packages from AUR...\n" || return 1
		verbose doas -u "$username" "$AURHELPER" -S --noconfirm "${aurs[@]}" || return 44
	fi

	if [ ! ${#flatpaks[@]} -eq 0 ]; then
		typer "Installing packages from flathub...\n" || return 1
		verbose flatpak install --assumeyes "${flatpaks[@]}" || return 45
	fi
}

sway_setup() {
	# Function used to configure the Desktop environment

	# Create home directories
	cd "/home/$username"
	mkdir "/home/$username/Stuff" "/home/$username/Downloads" "/home/$username/Desktop"

	# Install config files
	verbose git clone --depth=1 "$dotfiles" "/home/$username/temp_confs" || return 40

	cp -rl /home/$username/temp_confs/. /home/$username
	rm -rf /home/$username/temp_confs/
	typer "Configs installed, home directories created.\n" || return 1

	# Make sure the $username has rights for all their files
	verbose chown -R "$username:$username" "/home/$username"
	verbose chmod -R u+x "/home/$username/.local/bin/"
	verbose chmod -R u+rwx "${CACHE_DIR}"
	typer "Changed home files ownership.\n" || return 1

	# Enable required systemd services
	verbose systemctl enable bluetooth libvirtd udisks2 ufw sshd || return 46

	typer "Enabled systemd services.\n" || return 1
}

ending() {
	# Make last adjustments and greets the user

	typer "\nEverything was installed succesfully.\nThe system will reboot shortly, you then will be able to log in with your newly added user.\nSway window manager should start automatically.\n\nRoot user has been disabled, you can use doas for admin rights.\n\n\n\nIf you want to reboot on your own you can interrupt the script with 'Ctrl+C'\n\nHave fun with your brand new Archlinux system :) \n\n\n" || return 1

	for x in {1..5}; do
		echo "Rebooting system in $((6 - $x))..."
		sleep 3
	done

	systemctl reboot
}

#################################################################################
#                                  ACTUAL SCRIPT                                #
#################################################################################
flags "$@"

welcome || error "\nThe user exited or a cosmic ray hit a very vital part of your pc.\n"
sleep 1

adduserpass || error "\nThe user exited or a cosmic ray hit a very vital part of your pc.\n"
sleep 1

configure_packages || error "\nError while configuring packages, it could be that the packages file could not be downloaded (or a cosmic ray hit your pc).\n"
sleep 1

install_packages || error "\nThe script crashed while installing packages.\n"
sleep 1

sway_setup || error "\nThe script crashed while configuring sway and installing config files.\n"
sleep 1

aurchtistic_finalize || error "\nThe script crashed while creating autostart files.\n"
sleep 1

ending || error "\nThe script crashed at the end. You almost made it! (almost)\n"
