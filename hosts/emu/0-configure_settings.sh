#!/bin/bash

echo "DO NOT USE!"
exit 1

# Require root
if [[ $EUID -ne 0 ]]; then
   echo "[X] This script must be run as root. Use sudo." 
   exit 1
fi



###
#
# Ask for device to install CachyOS
#
#
echo "[!] Available NVMe drives:"
echo

# List NVMe disks with size and model info
lsblk -d -e7 -o NAME,SIZE,MODEL,SERIAL | grep nvme

echo
echo
read -rp "[!] Enter the device name to install CachyOS (e.g., nvme0n1): " devname
CACHYOS_DEVICE="/dev/$devname"

# Confirm the device exists and is a block device
if [[ ! -b "$CACHYOS_DEVICE" ]]; then
    echo "[X] Device $target not found."
    exit 1
fi


###
#
# Ask to separate /home partition
#
#
read -rp "[!] Use separate /home partition? (default: yes): " USE_HOME_PARTITION
if [[ -z "$USE_HOME_PARTITION" ]]; then
    USE_HOME_PARTITION="yes"
    while true; do
        read -rp "[!] Set /home size (e.g. 50GiB, 100GB, 512MiB, 50%) (default: 25%): " HOME_PARTITION_SIZE

        # Default to 250GiB if empty
        [[ -z "$HOME_PARTITION_SIZE" ]] && HOME_PARTITION_SIZE="25%"

        # Validate format (simple check)
	if [[ "$HOME_PARTITION_SIZE" =~ ^[0-9]+([.][0-9]+)?(mib|mib|mb|gib|gib|gb|tib|tib|tb|%)$ ]]; then
            break
        else
            echo "[X] Invalid format. Use something like 50GiB, 100GB, 512MiB."
        fi
    done
else
    USE_HOME_PARTITION=${USE_HOME_PARTITION,,}
fi


###
#
# Ask if use LUKS2
#
#
read -rp "[!] Use LUKS2 encryption? (default: yes): " USE_LUKS
if [[ -z "$USE_LUKS" ]]; then
    USE_LUKS="yes"
else
    USE_LUKS=${USE_LUKS,,}
fi


###
#
# Ask for hostname
#
#
read -rp "[!] Enter hostname (default: emu): " HOSTNAME
if [[ -z "$HOSTNAME" ]]; then
    HOSTNAME="emu"
fi

###
#
# Save Settings to settings.conf
#
#

# Set device
if grep -q "^CACHYOS_DEVICE=" "settings.conf" 2>/dev/null; then
    sed -i "s|^CACHYOS_DEVICE=.*|CACHYOS_DEVICE=${CACHYOS_DEVICE}|" "settings.conf"
else
    echo "CACHYOS_DEVICE=${CACHYOS_DEVICE}" >> "settings.conf"
fi

# /home
if grep -q "^USE_HOME_PARTITION=" "settings.conf" 2>/dev/null; then
    sed -i "s|^USE_HOME_PARTITION=.*|USE_HOME_PARTITION=${USE_HOME_PARTITION}|" "settings.conf"
else
    echo "USE_HOME_PARTITION=${USE_HOME_PARTITION}" >> "settings.conf"
fi
if [[ "$USE_HOME_PARTITION" == "yes" ]]; then
    if grep -q "^HOME_PARTITION_SIZE=" "settings.conf" 2>/dev/null; then
        sed -i "s|^HOME_PARTITION_SIZE=.*|HOME_PARTITION_SIZE=${HOME_PARTITION_SIZE}|" "settings.conf"
    else
        echo "HOME_PARTITION_SIZE=${HOME_PARTITION_SIZE}" >> "settings.conf"
    fi
fi

# Set luks2
if grep -q "^USE_LUKS=" "settings.conf" 2>/dev/null; then
    sed -i "s|^USE_LUKS=.*|USE_LUKS=${USE_LUKS}|" "settings.conf"
else
    echo "USE_LUKS=${USE_LUKS}" >> "settings.conf"
fi

# Set hostname
if grep -q "^HOSTNAME=" "settings.conf" 2>/dev/null; then
    sed -i "s|^HOSTNAME=.*|HOSTNAME=${HOSTNAME}|" "settings.conf"
else
    echo "HOSTNAME=${HOSTNAME}" >> "settings.conf"
fi

echo
echo "[!] settings.conf updated."
echo "----"
cat settings.conf
echo "----"
