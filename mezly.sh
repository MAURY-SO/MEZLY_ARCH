#! /bin/bash

clear
#discosdisponibles=$(echo "print devices" | parted | grep /dev/ | awk '{if (NR!=1) {print}}' | sed '/sr/d')
cat banner.txt

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

#DISK PARTICION

    date "+%F %H:%M"
	sleep 3
    echo "Formatting..."
    (echo Ignore) | sgdisk --zap-all ${disco}
    (echo 2; echo w; echo Y) | gdisk ${disco}
	sgdisk ${disco} -n=1:0:+500M -t=1:ef00
    sgdisk ${disco} -n=2:0:0
    fdisk -l ${disco} > /tmp/partition
	echo ""
	cat /tmp/partition
	sleep 10

