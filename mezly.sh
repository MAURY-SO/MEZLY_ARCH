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

#SYSTEM (USER)
    arch-chroot /mnt /bin/bash -c "(echo $password; echo $password) | passwd root"
    arch-chroot /mnt /bin/bash -c "useradd -m -g users -s /bin/bash $username"
    arch-chroot /mnt /bin/bash -c "(echo $password; echo $password) | passwd $username"
    sed -i "80i $username ALL=(ALL) ALL"  /mnt/etc/sudoers
    clear

#SYSTEM (LANGUAGE
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo -e ""
    echo -e "\t\t\t| Lenguage System|"
    echo -e ""
    echo "$idioma UTF-8" > /mnt/etc/locale.gen
    arch-chroot /mnt /bin/bash -c "locale-gen" 
    echo "LANG=$idioma" > /mnt/etc/locale.conf
    echo ""
    cat /mnt/etc/locale.conf 
    echo ""
    cat /mnt/etc/locale.gen
    sleep 4
    echo ""
    arch-chroot /mnt /bin/bash -c "export $(cat /mnt/etc/locale.conf)" 
    export $(cat /mnt/etc/locale.conf)
    arch-chroot /mnt /bin/bash -c "sudo -u $user export $(cat /etc/locale.conf)"
    export $(cat /etc/locale.conf)
    export $(cat /mnt/etc/locale.conf)
    exportlang=$(echo "LANG=$idioma")
    export $exportlang
    export LANG=$idioma
    locale-gen
    arch-chroot /mnt /bin/bash -c "locale-gen" 
    clear
    sleep 3

#SYSTEM (TIMEZONE)
    arch-chroot /mnt /bin/bash -c "pacman -Sy curl --noconfirm"
    curl https://ipapi.co/timezone > zonahoraria
    zonahoraria=$(cat zonahoraria)
    arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/$zonahoraria /etc/localtime"
    arch-chroot /mnt /bin/bash -c "timedatectl set-timezone $zonahoraria"
    arch-chroot /mnt /bin/bash -c "pacman -S ntp --noconfirm"
    arch-chroot /mnt /bin/bash -c "ntpd -qg"
    arch-chroot /mnt /bin/bash -c "hwclock --systohc"
    sleep 3
    rm zonahoraria
    clear

#SYSTEM (LOADKEYS)
    curl https://ipapi.co/languages | awk -F "," '{print $1}' | sed -e's/.$//' | sed -e's/.$//' | sed -e's/.$//' > keymap
    keymap=$(cat keymap)
    echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf 
    cat /mnt/etc/vconsole.conf 
    clear

#SYSTEM (MIRRORS in CHROOT)
    echo ""
    echo "Upgrade Mirrolist"
    echo ""
    arch-chroot /mnt /bin/bash -c "reflector --verbose --latest 15 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
    clear
    cat /mnt/etc/pacman.d/mirrorlist
    sleep 3
    clear

#SYSTEM (KERNEL ZEN)
    arch-chroot /mnt /bin/bash -c "pacman -S linux-firmware linux-zen linux-zen-headers mkinitcpio --noconfirm"
    clear

#SYSTEM (GRUB)
    clear
    arch-chroot /mnt /bin/bash -c "pacman -S grub efibootmgr os-prober dosfstools --noconfirm"
    echo '' 
    echo 'Installing EFI System >> bootx64.efi' 
    arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --removable' 
    echo '' 
    echo 'Installing UEFI System >> grubx64.efi' 
    arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch'
    ######
    sed -i "6iGRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"" /mnt/etc/default/grub
    sed -i '7d' /mnt/etc/default/grub
    ######
    echo ''
    arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
    echo '' 
    echo 'ls -l /mnt/efi' 
    ls -l /mnt/efi 
    echo '' 
    echo 'Lea bien que no tenga ningún error marcado' 
    echo '> Confirme tener las IMG de linux para el arranque' 
    echo '> Confirme tener la carpeta de GRUB para el arranque' 
    sleep 4
    clear

#SYSTEM (ETHERNET - WIFI)
    arch-chroot /mnt /bin/bash -c "pacman -S dhcpcd networkmanager iwd net-tools ifplugd --noconfirm"
    arch-chroot /mnt /bin/bash -c "systemctl enable dhcpcd NetworkManager"
    arch-chroot /mnt /bin/bash -c "pacman -S iw wireless_tools wpa_supplicant dialog wireless-regdb --noconfirm"
    echo "noipv6rs" >> /mnt/etc/dhcpcd.conf
    echo "noipv6" >> /mnt/etc/dhcpcd.conf
    clear

#SYSTEM (SHELL)
    arch-chroot /mnt /bin/bash -c "pacman -S fish --noconfirm"
    SH=fish
    arch-chroot /mnt /bin/bash -c "chsh -s /bin/$SH"
    arch-chroot /mnt /bin/bash -c "chsh -s /usr/bin/$SH $username"
    arch-chroot /mnt /bin/bash -c "chsh -s /bin/$SH $username"
    clear

#SYSTEM (USER FOLDERS)
    arch-chroot /mnt /bin/bash -c "pacman -S git wget lsb-release xdg-user-dirs --noconfirm"
    arch-chroot /mnt /bin/bash -c "xdg-user-dirs-update"
    echo ""
    arch-chroot /mnt /bin/bash -c "ls /home/$username"
    sleep 5
    clear

#SYSTEM (VIDEO-GENERIC)
    arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-vesa xf86-video-fbdev mesa mesa-libgl lib32-mesa --noconfirm"

#SYSTEM (PROFILE)

    case $profile in
        1)
            echo "PROFILE -> KDE"
            #Plasma minimal
            arch-chroot /mnt /bin/bash -c "pacman -S plasma dolphin konsole discover sddm ffmpegthumbs ffmpegthumbnailer --noconfirm"
            arch-chroot /mnt /bin/bash -c "systemctl enable sddm"
            arch-chroot /mnt /bin/bash -c "pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber helvum"
        	arch-chroot /mnt /bin/bash -c "pacman -S gnu-free-fonts ttf-hack ttf-inconsolata gnome-font-viewer --noconfirm"
	        clear
	        arch-chroot /mnt /bin/bash -c "pacman -S firefox --noconfirm"
	        clear

            ;;
        *)
            echo "PROFILE -> CLI"
            ;;
    esac

#SYSTEM (UNMOUNT - REBOOT)
    umount -R /mnt
    swapoff -a
    clear
    echo "Your system is installed!!!"
    sleep 5
    reboot