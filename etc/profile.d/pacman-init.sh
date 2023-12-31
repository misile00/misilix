#!/bin/sh
Red='\033[0;31m' 
Blue='\033[0;34m'
Yellow='\033[0;33m'
NC='\033[0m' # No Color

if sudo -n true
then
    pacman --init
    pacman --populate archlinuxarm
    rm /etc/profile.d/pacman-init.sh
else
    echo -e "\n\n${Blue}To use pacman properly, initialize the pacman keyring and populate the Arch Linux ARM package signing keys:\n${Red}root${NC}${Blue}# ${Yellow}pacman-key --init\n${Red}root${NC}${Blue}# ${Yellow}pacman-key --populate archlinuxarm\n${Red}root${NC}${Blue}# ${Yellow}rm /etc/profile.d/pacman-init.sh"
fi
