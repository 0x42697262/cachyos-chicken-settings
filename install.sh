#!/bin/bash

if (( EUID != 0)); then
    echo "You must be root to install CachyOS." 1>&2
    exit 100
fi


#
# This install script is based of the Calamares installer of CachyOS
# Source: https://github.com/CachyOS/cachyos-calamares/blob/cachyos-systemd-qt6/src/modules/
#

#
## shellprocess@modify_mk_hook
#
# disables running mkinitcpio while install process, it will be called once with initcpio module
# enable_mk_hook needs to be run at the ende of install process in settings.conf to "reanable" 90-mkinitcpio-install.hook for installed system
# pacstrap needs the hook to be present on "host" but the script needs to be present inside chroot so we copy modified hook to host and script to chroot.
# for pacman installing DE/WM and common packages inside chroot it needs hook present in chroot so we copy that also inside.
mkdir -p /etc/pacman.d/hooks/
cp /etc/calamares/scripts/90-mkinitcpio-install.hook /etc/pacman.d/hooks/

mkdir -p /mnt/usr/share/libalpm/scripts/
cp /etc/calamares/scripts/mkinitcpio-install-calamares /mnt/usr/share/libalpm/scripts/
chmod +x /mnt/usr/share/libalpm/scripts/mkinitcpio-install-calamares

mkdir -p /mnt/etc/pacman.d/hooks/
cp /etc/calamares/scripts/90-mkinitcpio-install.hook /mnt/etc/pacman.d/hooks/

#
## shellprocess@initialize_pacman
#
# generate pacman keyring, mirrorlist and copy them into target system
bash /etc/calamares/scripts/update-mirrorlist
pacman -Sy --noconfirm archlinux-keyring cachyos-keyring
chmod +x /etc/calamares/scripts/create-pacman-keyring

mkdir -p /mnt/etc/pacman.d/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
cp /etc/pacman.d/cachyos-mirrorlist /mnt/etc/pacman.d/
cp /etc/pacman.d/cachyos-v3-mirrorlist /mnt/etc/pacman.d/
cp /etc/pacman.d/cachyos-v4-mirrorlist /mnt/etc/pacman.d/
cp -a /etc/pacman.d/gnupg /mnt/etc/pacman.d/
cp /etc/resolv.conf /mnt/etc/


#
## pacstrap
#
# This module installs the base system and then copies files
# into the installation that will be used in the installed system
#
pacstrap -K /mnt \
    cachyos-hooks \
    cachyos-keyring \
    cachyos-mirrorlist \
    cachyos-v4-mirrorlist \
    cachyos-v3-mirrorlist \
    cachyos-rate-mirrors \
    cachyos-settings \
    plymouth \
    cachyos-plymouth-theme \
    linux-cachyos \
    linux-cachyos-headers \
    linux-firmware


#
# postInstallFiles is an array of file names which will be copied into the system
#
# The paths should be relative to the host and the files will be copied to the
# location in the installed system
#
## postInstallFiles:
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman-more.conf /mnt/etc/pacman-more.conf
cp /etc/mkinitcpio.conf /mnt/etc/mkinitcpio.conf
cp /usr/local/bin/dmcheck /mnt/usr/local/bin/dmcheck
cp /usr/local/bin/remove-nvidia /mnt/usr/local/bin/remove-nvidia
cp /etc/calamares/scripts/try-v3 /mnt/etc/calamares/scripts/try-v3
cp /etc/calamares/scripts/remove-ucode /mnt/etc/calamares/scripts/remove-ucode
cp /etc/calamares/scripts/enable-ufw /mnt/etc/calamares/scripts/enable-ufw


#
## locale
#

if grep -q "^en_US.UTF-8 UTF-8" /mnt/etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" | tee --append /mnt/etc/locale.gen
fi
if grep -q "^ja_JP.UTF-8 UTF-8" /etc/locale.gen; then
    echo "ja_JP.UTF-8 UTF-8" | tee --append /mnt/etc/locale.gen
fi
cat <<EOF | tee /mnt/etc/locale.conf > /dev/null
LANG=en_US.UTF-8
LC_ADDRESS=ja_JP.UTF-8
LC_CTYPE=en_US.UTF-8
LC_COLLATE=en_US.UTF-8
LC_IDENTIFICATION=ja_JP.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_MESSAGES=en_US.UTF-8
LC_NAME=ja_JP.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_PAPER=en_US.UTF-8
LC_TELEPHONE=ja_JP.UTF-8
LC_TIME=ja_JP.UTF-8
EOF


#
## fstab
#
genfstab -U /mnt | tee /mnt/etc/fstab


#
## shellprocess@before-online
#
#/etc/calamares/scripts/try-v3
#rm /etc/calamares/scripts/try-v3

#
## initcpiocfg
#
#source /etc/mkinitcpio.conf
#mkinitcpio -p linux-cachyos

#makepkg -si ./PKGBUILD
