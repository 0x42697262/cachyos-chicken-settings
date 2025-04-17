mkdir -p /etc/pacman.d/
cp pkg/cachyos-mirrorlist /etc/pacman.d/
cp pkg/cachyos-v3-mirrorlist /etc/pacman.d/
cp pkg/cachyos-v4-mirrorlist /etc/pacman.d/
cp pkg/mirrorlist /etc/pacman.d/
cp pkg/pacman-more.conf /etc/pacman-more.conf
cp pkg/pacman.conf /etc/pacman.conf
pacman -Sy --noconfirm archlinux-keyring cachyos-keyring
