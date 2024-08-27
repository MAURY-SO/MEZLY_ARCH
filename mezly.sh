#! /bin/bash

clear
discosdisponibles=$(echo "print devices" | parted | grep /dev/ | awk '{if (NR!=1) {print}}' | sed '/sr/d')
cat banner.txt

#COLOURS
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    RESET='\033[0m'
    BOLD='\033[1m'

#INFO
    
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Rutas de Disco disponible: "
    echo ""
    echo $discosdisponibles
    echo ""
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    read -p "path disk -> " disco
    read -p "username -> " username
    read -p "password -> " password
    read -p "Profile (1.KDE / 2.MINIMAL) -> " profile
    echo ""
    echo "Press ENTER to continue or CTRL + C to exit"
    read line

#PARTITIONS
    clear
    echo -e "Hello ${BOLD}$username${RESET}"
    date "+%F %H:%M"
	sleep 3
    echo -e "${BOLD}${GREEN}Partition of unit...${RESET}"
    (echo Ignore) | sgdisk --zap-all ${disco}
    (echo 2; echo w; echo Y) | gdisk ${disco}
	sgdisk ${disco} -n=1:0:+500M -t=1:ef00
    sgdisk ${disco} -n=2:0:0
    fdisk -l ${disco} > /tmp/partition
	echo ""
	cat /tmp/partition
	
    partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"

    echo $partition | awk -F ' ' '{print $1}' >  boot-efi
	echo $partition | awk -F ' ' '{print $2}' >  root-efi

    #PARTITIONS
    clear
    echo -e "${BOLD}Your EFI partition is:${RESET}" 
	cat boot-efi
    echo -e "${BOLD}Your ROOT partition is:${RESET}" 
	cat root-efi
    sleep 3

    #Formatting Partitions
    echo -e "${BOLD}${GREEN}Formatting Partitions...${RESET}"
    sleep 2
    mkfs.ext4 $(cat root-efi) 
	mkfs.fat -F 32 $(cat boot-efi) 

    mount $(cat root-efi) /mnt
	mount --mkdir $(cat boot-efi) /mnt/efi 

    rm boot-efi
	rm root-efi

    clear
	echo ""
	echo "${BOLD}${GREEN}Check the mount point at MOUNTPOINT - PRESS ENTER${RESET}"
	echo ""
	lsblk -l
	read line

# #MIRRORS
#     clear
#     pacman -Sy reflector python --noconfirm