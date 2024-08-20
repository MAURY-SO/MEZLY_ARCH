#! /bin/bash

clear
cat banner.txt

#INFO

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    read -p "username -> " username
    read -p "password -> " password
    read -p "Profile (1.KDE / 2.MINIMAL) -> " profile
    echo ""
    echo "Press ENTER to continue or CTRL + C to exit"
    read line
    echo ""
    echo "DONE!"
    echo ""

    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    date "+%F %H:%M"
    sleep 3

#PARTICION

    swapsize=$(free --giga | awk '/^Mem:/{print $2}')
    #dd if=/dev/zero of="${disco}" bs=4M conv=fsync oflag=direct status=progress
    (echo Ignore) | sgdisk --zap-all ${disco}
    #parted ${disco} mklabel gpt
    (echo 2; echo w; echo Y) | gdisk ${disco}
    sgdisk ${disco} -n=1:0:+100M -t=1:ef00
    sgdisk ${disco} -n=2:0:+${swapsize}G -t=2:8200
    sgdisk ${disco} -n=3:0:0
    fdisk -l ${disco} > /tmp/partition
    echo ""
    cat /tmp/partition
    sleep 3

    partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"

    echo $partition | awk -F ' ' '{print $1}' >  boot-efi
    echo $partition | awk -F ' ' '{print $2}' >  swap-efi
    echo $partition | awk -F ' ' '{print $3}' >  root-efi

    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Your EFI partition is:" 
    cat boot-efi
    echo ""
    echo "Your SWAP partition is:"
    cat swap-efi
    echo ""
    echo "Your ROOT partition is:"
    cat root-efi
    sleep 3

    clear
    echo ""
    echo "Formatting Partitions"
    echo ""
    mkfs.ext4 $(cat root-efi) 
    mount $(cat root-efi) /mnt 

    mkdir -p /mnt/efi 
    mkfs.fat -F 32 $(cat boot-efi) 
    mount $(cat boot-efi) /mnt/efi 

    mkswap $(cat swap-efi) 
    swapon $(cat swap-efi)

    rm boot-efi
    rm swap-efi
    rm root-efi

    clear
    echo ""
    echo "Check the mount point at MOUNTPOINT - PRESS ENTER"
    echo ""
    lsblk -l
    sleep 5

#SYSTEM (KEYS AND MIRRORLIST)

    clear
    pacman -Syy
    pacman -Sy archlinux-keyring --noconfirm 
    clear
    pacman -Sy reflector python rsync glibc curl --noconfirm 
    sleep 3
    clear
    echo ""
    echo "Update List MirrorList"
    echo ""
    reflector --verbose --latest 5 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    clear
    cat /etc/pacman.d/mirrorlist
    sleep 3
    clear

#SYSTEM (SYSTEM BASE)
    echo ""
    echo "Install system base"
    echo ""
    pacstrap /mnt base base-devel nano reflector python rsync
    clear

#SYSTEM (FSTAB)
    echo ""
    echo "File FSTAB"
    echo ""
    echo "genfstab -p /mnt >> /mnt/etc/fstab"
    echo ""
    genfstab -p /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab
    sleep 4
    clear

#SYSTEM (PACMAN CUSTOM)
    sed -i 's/#Color/Color/g' /mnt/etc/pacman.conf
    sed -i 's/#TotalDownload/TotalDownload/g' /mnt/etc/pacman.conf
    sed -i 's/#VerbosePkgLists/VerbosePkgLists/g' /mnt/etc/pacman.conf
    sed -i "37i ILoveCandy" /mnt/etc/pacman.conf
    sed -i 's/#[multilib]/[multilib]/g' /mnt/etc/pacman.conf
    sed -i "s/#Include = /etc/pacman.d/mirrorlist/Include = /etc/pacman.d/mirrorlist/g" /mnt/etc/pacman.conf
    clear

#SYSTEM (HOST)

    clear
    hostname=mezly
    echo "$hostname" > /mnt/etc/hostname
    echo "127.0.1.1 $hostname.localdomain $hostname" > /mnt/etc/hosts
    clear
    echo "Hostname: $(cat /mnt/etc/hostname)"
    echo ""
    echo "Hosts: $(cat /mnt/etc/hosts)"
    echo ""
    clear