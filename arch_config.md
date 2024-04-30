# Intro

## User
- Add new user
- Add user to wheel
- set user home directory

## Configs
- Download files from github:
  - csv packages list
    - Each entry has package name and a description which is shown while installing
  - csv aur packages list 
  - folder with .conf files
  - various bash scripts for desktop tools
  - txt with systemd services to activate
  - flatpak file list




# Main install

## Pacman
- Configure pacman with config file
- Rank mirrors with mirrorlist script

## Miscellaneous
- Change default shell for new users to zsh (etc/default/useradd)

## Kernel/Bootloader (maybe)
- check if you have grub or anything else
- give option to add uefi entry

## Admin rights
- Configure /etc/doas.conf 
  - allow user to use doas without password prompt (remove it at end of script)
- Create symlink to sudo

## Packages
- Install packages from csv file
- Install paru packet manager from the AUR


## Language check
- Check if locale is correctly set and ask user to configure it





# Desktop environment

## Configs
- Install user configs for programs
- Install .zprofile and .zshrc configs

## Flatpak
- Install flatpak packages
- Configure flatseal permits

## SWAY (Windows tiling manager)
- Enable systemd services from file
- Setup keepassxc as keyring service
- Copy scripts folder to home

## Librewolf
- Create user profile
- Install add-ons

## Brave browser
- Create user profile
- Install crypto add-ons




# Security

## Firewall
- Block all ports with ufw

## SSH
- Ask user if they want to enable ssh server
  - If yes:
    - Open 22 port with ufw
    - Enable sshd daemon
    - disable root account ssh login

## Miscellaneous
- check for mount options for security
- change umask settings




# Extras (maybe)

## Encryption check
- Check if system has encryption enabled
  - If yes:
    - Install clevis and tpm tools
    - Check if TPM2.0 is present and install keys on it with clevis hook

## Secure Boot
- Check if secure boot is in custom mode 
  - If yes:
      - Ask the user if they want to sign the bootloader with it
        - If yes:
          - Install sbctl and sign .efi files

## BTRFS
- Check if btrfs is installed
  - If yes:
    - Make snapshot of filesystem
    - Set up cron timer for btrfs bash script for taking automatic snapshots of system
    - Create vault subvolume and mount it in home (so it can't be snapshot, and thus save disk space)

## Microcode
- Check if microcode is installed and tell the user to install it 

## CUPS
- Ask user if they want to set up CUPS printing system
  - If yes:
    - Install CUPS
    - Enable systemd cups service

## Fonts Configuration





# Last steps

## Extra personal config 
- Ask to install nextcloud and protonvpn
  - If yes:
    - Configure folders in home directory like my personal config

## Security
- Set login delay for pamd
- Lock out user after login attempts
- DNS over https
- disable root account
- remove doas without password prompt

## Others
- Remove config files
- Create welcome message to tell the user additional things to do
- Reboot the system






# Optionals (maybe)

- https://wiki.archlinux.org/title/Security#SUID_and_SGID_files
- hibernation 





# Notes

- All commands are to be executed with root user, except those cases where you need to use user account (like fakeroot environment 
for makepkg), in those instances we use "doas -u"
