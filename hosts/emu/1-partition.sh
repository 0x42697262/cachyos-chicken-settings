#!/bin/bash

CONFIG_FILE="settings.conf"

# Require root
if [[ $EUID -ne 0 ]]; then
   echo "[X] This script must be run as root. Use sudo."
   exit 1
fi

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "[X] Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "CachyOS Device: $CACHYOS_DEVICE"

sudo parted $CACHYOS_DEVICE -- mklabel gpt
sudo parted $CACHYOS_DEVICE -- mkpart ESP fat32 1MiB 2049MiB
sudo parted $CACHYOS_DEVICE -- set 1 esp on
sudo parted $CACHYOS_DEVICE -- mkpart CachyOS ext4 2049MiB 100%

sleep 2
BOOT_PARTITION=$(lsblk -no PATH,PARTLABEL "$CACHYOS_DEVICE" | grep 'ESP' | awk '{print $1}')
LUKS_CONTAINER=$(lsblk -no PATH,PARTLABEL "$CACHYOS_DEVICE" | grep 'CachyOS' | awk '{print $1}')

sudo mkfs.fat -F 32 $BOOT_PARTITION
echo "[!] Formatted (${BOOT_PARTITION}) as boot partition."

echo "[+] To start encrypting ${LUKS_CONTAINER} partition with LUKS2."

if [[ -z "$LUKS_CONTAINER" ]]; then
    echo "[X] Could not find CachyOS partition. Exiting."
    exit 1
fi

sudo cryptsetup --verify-passphrase -v luksFormat $LUKS_CONTAINER
sudo cryptsetup open $LUKS_CONTAINER cryptroot

CRYPTROOT=/dev/mapper/cryptroot

echo "[+] Creating Physical Volume on ${CRYPTROOT}"
sudo pvcreate $CRYPTROOT
echo "[+] Creating Volume Group on ${CRYPTROOT}"
sudo vgcreate vg0 $CRYPTROOT
echo "[+] Creating logical volumes"
sudo lvcreate -L $HOME_PARTITION_SIZE -n root vg0
sudo lvcreate -L $ROOT_PARTITION_SIZE -n home vg0
sudo lvcreate -l 100%FREE -n isekai vg0

sudo mkfs.xfs /dev/vg0/root
sudo mkfs.xfs /dev/vg0/home
sudo mkfs.xfs /dev/vg0/isekai
