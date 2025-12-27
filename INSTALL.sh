#!/bin/bash

# Arch Linux GNOME Minimal Installation Script
# Run this script after base system installation (arch-chroot)

set -e  # Exit on error

echo "================================"
echo " Arch Linux GNOME Setup Script"
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

# Install Xorg
print_status "Installing Xorg..."
pacman -S --noconfirm xorg-server xorg-apps

# Install GNOME
print_status "Installing GNOME Desktop Environment..."
pacman -S --noconfirm gnome gnome-extra

# Enable GDM
print_status "Enabling GDM..."
pacman -S --noconfirm gdm
systemctl enable gdm.service

# Productivity apps
print_status "Installing GNOME productivity apps..."
pacman -S --noconfirm \
    gnome-calendar gnome-contacts gnome-weather gnome-clocks \
    gnome-maps gnome-calculator gnome-notes evince eog totem \
    gnome-music gnome-photos gnome-todo gnome-sound-recorder

# Browser
print_status "Installing Firefox..."
pacman -S --noconfirm firefox

# Email client
print_status "Installing Evolution..."
pacman -S --noconfirm evolution

# Office suite
print_status "Installing LibreOffice..."
pacman -S --noconfirm libreoffice-fresh

# PDF support
pacman -S --noconfirm poppler

# Media codecs
print_status "Installing media codecs..."
pacman -S --noconfirm \
    gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad \
    gst-plugins-ugly gst-libav ffmpeg

# Archive tools
print_status "Installing archive tools..."
pacman -S --noconfirm file-roller unzip zip p7zip unrar

# NetworkManager
print_status "Setting up NetworkManager..."
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service

# Bluetooth
print_status "Installing Bluetooth support..."
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service

# Audio (PipeWire)
print_status "Installing PipeWire audio stack..."
pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

# Printing
print_status "Installing printing support..."
pacman -S --noconfirm cups
systemctl enable cups.service

# System utilities
print_status "Installing system utilities..."
pacman -S --noconfirm \
    base-devel git wget curl nano vim htop neofetch

# Fonts
print_status "Installing fonts..."
pacman -S --noconfirm \
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji

# Time sync
print_status "Enabling time synchronization..."
timedatectl set-ntp true

# User setup
print_status "Creating user account..."
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

# Hostname
print_status "Setting hostname..."
read -p "Enter hostname: " hostname
hostnamectl set-hostname "$hostname"

cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain $hostname
EOF

# Locale
print_status "Configuring locale..."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Timezone
print_status "Setting timezone..."
read -p "Enter timezone (e.g., America/New_York): " timezone

if [ ! -f "/usr/share/zoneinfo/$timezone" ]; then
    print_error "Invalid timezone. Check spelling and try again."
    exit 1
fi

ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Install yay (AUR helper)
print_status "Installing yay (AUR helper)..."
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

print_warning "Please reboot your system to start GNOME."

read -p "Reboot now? (y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    print_status "Rebooting..."
    reboot
else
    print_status "Reboot manually when ready."
fi
