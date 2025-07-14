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






