#!/bin/bash

if (( EUID != 0)); then
    echo "You must be root to install CachyOS." 1>&2
    exit 100
fi

pacstrap -K /mnt \
    cachyos-hooks \
    cachyos-keyring \
    cachyos-mirrorlist \
    cachyos-v4-mirrorlist \
    cachyos-v3-mirrorlist \
    cachyos-rate-mirrors \
    cachyos-settings \
    linux-cachyos \
    linux-cachyos-headers \
    linux-firmware


# shellprocess@modify_mk_hook
# disables running mkinitcpio while install process, it will be called once with initcpio module
# enable_mk_hook needs to be run at the ende of install process in settings.conf to "reanable" 90-mkinitcpio-install.hook for installed system
# pacstrap needs the hook to be present on "host" but the script needs to be present inside chroot so we copy modified hook to host and script to chroot.
# for pacman installing DE/WM and common packages inside chroot it needs hook present in chroot so we copy that also inside.
#
mkdir -p /etc/pacman.d/hooks/
cp /etc/calamares/scripts/90-mkinitcpio-install.hook /etc/pacman.d/hooks/

mkdir -p /mnt/usr/share/libalpm/scripts/
cp /etc/calamares/scripts/mkinitcpio-install-calamares /mnt/usr/share/libalpm/scripts/
chmod +x /mnt/usr/share/libalpm/scripts/mkinitcpio-install-calamares

mkdir -p /mnt/etc/pacman.d/hooks/
cp /etc/calamares/scripts/90-mkinitcpio-install.hook /mnt/etc/pacman.d/hooks/


# shellprocess@initialize_pacman
# generate pacman keyring, mirrorlist and copy them into target system
#
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

#makepkg -si ./PKGBUILD
