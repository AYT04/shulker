#!/bin/bash

# Arch Linux GNOME Minimal Installation Script
# Run this script after base system installation (arch-chroot)

set -e  # Exit on error

echo "================================"
echo "Setup Script"
echo "Based on Arch Linux"
echo "================================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Ensure root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root or inside arch-chroot"
    exit 1
fi

# Update system
print_status "Updating system..."
pacman -Syu --noconfirm
pacman -S --noconfirm xorg-server xorg-apps
pacman -S --noconfirm gnome gnome-extra
pacman -S --noconfirm gdm
systemctl enable gdm.service

# Productivity apps
print_status "Installing some productivity apps..."
pacman -S --noconfirm \
    gnome-calendar gnome-contacts gnome-weather gnome-clocks \
    gnome-maps gnome-calculator gnome-notes evince eog totem \
    gnome-music gnome-photos gnome-todo gnome-sound-recorder \
    firefox brave-browser evolution libreoffice-fresh poppler \
    gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad \
    gst-plugins-ugly gst-libav ffmpeg file-roller unzip zip p7zip \
    base-devel git wget curl nano vim htop neofetch ttf-dejavu \
    ttf-liberation noto-fonts noto-fonts-emoji


pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
pacman -S --noconfirm cups
systemctl enable cups.service

timedatectl set-ntp true

read -p "Enter username: " username

if id "$username" &>/dev/null; then
    print_warning "User already exists, skipping creation."
else
    useradd -m -G wheel,audio,video,storage,optical -s /bin/bash "$username"
    echo "Set password for $username:"
    passwd "$username"

    print_status "Enabling sudo for wheel group..."
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
fi

read -p "Enter hostname: " hostname
hostnamectl set-hostname "$hostname"

cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain $hostname
EOF

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

read -p "Enter timezone (e.g., America/Waterloo): " timezone

if [ ! -f "/usr/share/zoneinfo/$timezone" ]; then
    print_error "Invalid timezone. Check spelling and try again."
    exit 1
fi

ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

if ! command -v yay &>/dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    chown -R "$username":"$username" yay
    cd yay
    sudo -u "$username" makepkg -si --noconfirm
fi

print_status "================================"
print_status "Installation Complete!"
print_status "================================"

read -p "Restart Now? (y/N): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    print_status "Rebooting..."
    reboot
else
    print_status "Reboot manually when ready."
fi