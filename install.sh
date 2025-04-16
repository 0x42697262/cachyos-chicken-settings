#!/bin/bash

# Defining colours
BRed="\e[1;31m"
BGreen="\e[1;32m"
BYellow="\e[1;33m"
BBlue="\e[1;34m"
End_Colour="\e[0m"

if (( EUID != 0)); then
    echo "You must be root to install CachyOS." 1>&2
    exit 100
fi
USER=birb


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
echo -e "${BYellow}[ * ]Running shellprocess@modify_mk_hook${End_Colour}"
mkdir -p /etc/pacman.d/hooks/
cp /etc/calamares/scripts/90-mkinitcpio-install.hook /etc/pacman.d/hooks/

echo -e "${BYellow}[ * ]Copying mkinitcpio-install-calamares${End_Colour}"
mkdir -p /mnt/usr/share/libalpm/scripts/
cp /etc/calamares/scripts/mkinitcpio-install-calamares /mnt/usr/share/libalpm/scripts/
chmod +x /mnt/usr/share/libalpm/scripts/mkinitcpio-install-calamares

echo -e "${BYellow}[ * ]Copying 90-mkinitcpio-install.hook${End_Colour}"
mkdir -p /mnt/etc/pacman.d/hooks/
cp /etc/calamares/scripts/90-mkinitcpio-install.hook /mnt/etc/pacman.d/hooks/

#
## shellprocess@initialize_pacman
#
# generate pacman keyring, mirrorlist and copy them into target system
echo -e "${BYellow}[ * ]Running shellprocess@initialize_pacman${End_Colour}"
echo -e "${BYellow}[ * ]Updating mirrorlist${End_Colour}"
bash /etc/calamares/scripts/update-mirrorlist
pacman -Sy --noconfirm archlinux-keyring cachyos-keyring
chmod +x /etc/calamares/scripts/create-pacman-keyring

echo -e "${BYellow}[ * ]Copying mirrorlist${End_Colour}"
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
echo -e "${BYellow}[ * ]Running pacstrap${End_Colour}"
pacstrap -K /mnt \
    base \
    base-devel \
    cachyos-fish-config \
    cachyos-hooks \
    cachyos-keyring \
    cachyos-mirrorlist \
    cachyos-plymouth-theme \
    cachyos-rate-mirrors \
    cachyos-settings \
    cachyos-v3-mirrorlist \
    cachyos-v4-mirrorlist \
    cryptsetup \
    linux-cachyos \
    linux-cachyos-headers \
    linux-firmware \
    lvm2 \
    mkinitcpio \
    networkmanager \
    paru \
    plymouth \
    sudo \
    systemd-boot-manager \
    ufw \
    usbutils \
    util-linux

#
# postInstallFiles is an array of file names which will be copied into the system
#
# The paths should be relative to the host and the files will be copied to the
# location in the installed system
#
## postInstallFiles:
echo -e "${BYellow}[ * ]Copying Post Install Files${End_Colour}"
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman-more.conf /mnt/etc/pacman-more.conf
cp /etc/mkinitcpio.conf /mnt/etc/mkinitcpio.conf
cp /usr/local/bin/dmcheck /mnt/usr/local/bin/dmcheck
cp /usr/local/bin/remove-nvidia /mnt/usr/local/bin/remove-nvidia
mkdir -p /mnt/etc/calamares/scripts/
cp /etc/calamares/scripts/try-v3 /mnt/etc/calamares/scripts/try-v3
cp /etc/calamares/scripts/remove-ucode /mnt/etc/calamares/scripts/remove-ucode
cp /etc/calamares/scripts/enable-ufw /mnt/etc/calamares/scripts/enable-ufw


#
## locale
#

echo -e "${BYellow}[ * ]Running locale${End_Colour}"
echo -e "${BYellow}[ * ]Adding en_US to locale${End_Colour}"
if ! arch-chroot /mnt grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
    arch-chroot /mnt bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen'
fi
echo -e "${BYellow}[ * ]Adding ja_JP to locale${End_Colour}"
if ! arch-chroot /mnt grep -q "^ja_JP.UTF-8 UTF-8" /etc/locale.gen; then
    arch-chroot /mnt bash -c 'echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen'
fi
echo -e "${BYellow}[ * ]Generating locale${End_Colour}"
arch-chroot /mnt locale-gen

echo -e "${BYellow}[ * ]Creating locale.conf${End_Colour}"
arch-chroot /mnt cat <<EOF | tee /mnt/etc/locale.conf > /dev/null
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
echo -e "${BYellow}[ * ]Generating /etc/fstab${End_Colour}"
genfstab -U /mnt | arch-chroot /mnt tee /etc/fstab


#
## shellprocess@before-online
#
echo -e "${BYellow}[ * ]Checking for V3 support${End_Colour}"
arch-chroot /mnt /etc/calamares/scripts/try-v3
arch-chroot /mnt rm /etc/calamares/scripts/try-v3


#
## initcpiocfg
#
echo -e "${BYellow}[ * ]Updating mkinitcpio hooks${End_Colour}"
arch-chroot /mnt sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd udev autodetect microcode modconf kms keyboard keymap consolefont sd-encrypt block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

echo -e "${BYellow}[ * ]Running mkinitcpio${End_Colour}"
arch-chroot /mnt bash -c "source /etc/mkinitcpio.conf && mkinitcpio -P"


#
## users
#
echo -e "${BYellow}[ * ]Adding user $USER${End_Colour}"
arch-chroot /mnt useradd -m $USER
arch-chroot /mnt usermod -aG $USER,sys,network,rfkill,users,video,storage,lp,audio,wheel $USER

echo -e "${BYellow}[ * ]Adding user $USER to sudoers${End_Colour}"
arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee' visudo -f /etc/sudoers.d/wheel"

echo -e "${BYellow}[ * ]Changing shell of user $USER to /bin/fish${End_Colour}"
arch-chroot /mnt chsh -s /bin/fish $USER

echo -e "${BRed}[ * ]SET ROOT PASSWORD${End_Colour}"
arch-chroot /mnt passwd 
echo -e "${BRed}[ * ]SET USER $USER PASSWORD${End_Colour}"
arch-chroot /mnt passwd $USER 

echo -e "${BYellow}[ * ]Setting hostname${End_Colour}"
arch-chroot /mnt bash -c "echo PlasmaPhoenix > /etc/hostname"


#
## shellprocess@removeucode
#
echo -e "${BYellow}[ * ]Removing unused microcode${End_Colour}"
arch-chroot /mnt bash -c "/etc/calamares/scripts/remove-ucode"
arch-chroot /mnt rm /etc/calamares/scripts/remove-ucode


#
## shellprocess@reset_mk_hook
#
echo -e "${BYellow}[ * ]Resetting mkinitcpio hooks${End_Colour}"
arch-chroot /mnt rm /etc/pacman.d/hooks/90-mkinitcpio-install.hook
arch-chroot /mnt rm /usr/share/libalpm/scripts/mkinitcpio-install-calamares


#
## services-systemd
#
echo -e "${BYellow}[ * ]Enabling systemd services${End_Colour}"
arch-chroot /mnt systemctl enable NetworkManager ufw multi-user.target fstrim.timer


#
## shellprocess
#
echo -e "${BYellow}[ * ]Executing shellprocess cleanup${End_Colour}"
arch-chroot /mnt rm /etc/systemd/system/etc-pacman.d-gnupg.mount
arch-chroot /mnt rm /etc/systemd/system/display-manager.service
arch-chroot /mnt /usr/local/bin/dmcheck
arch-chroot /mnt rm /usr/local/bin/dmcheck
arch-chroot /mnt rm -rf /home/liveuser
arch-chroot /mnt runuser $USER -c "cp -rf /etc/skel/. /home/$USER/."
arch-chroot /mnt runuser $USER -c "rm -rf /home/$USER/{.xsession,.xprofile,.xinitrc}"


#
## shellprocess@enable_sdboot
#
echo -e "${BYellow}[ * ]Generating systemd-boot${End_Colour}"
arch-chroot /mnt rm -rf /boot/loader/entries/*
arch-chroot /mnt sdboot-manage setup
arch-chroot /mnt sdboot-manage gen


#
## shellprocess@enable_ufw
#
echo -e "${BYellow}[ * ]Enabling UFW${End_Colour}"
arch-chroot /mnt /etc/calamares/scripts/enable-ufw
arch-chroot /mnt rm /etc/calamares/scripts/enable-ufw
