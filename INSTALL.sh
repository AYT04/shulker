#!/bin/bash

# ShulkerOS Professional Installation Script
# A modular approach to Arch Linux GNOME setup

set -e # Exit on error
set -u # Treat unset variables as an error

# --- Configuration & Colors ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# --- UI Functions ---
log_info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Validation ---
check_requirements() {
    if [[ "$EUID" -ne 0 ]]; then
        log_error "This script must be run as root (inside arch-chroot)."
        exit 1
    fi
}

# --- Installation Modules ---
#making my own DE, so GNOME will have to do for now..
update_system() {
    log_info "Updating system and installing base X11/GNOME packages..."
    pacman -Syu --noconfirm
    pacman -S --noconfirm xorg-server gnome gnome-extra gdm
    systemctl enable gdm.service
}

install_productivity() {
    log_info "Installing productivity suite..."
    # Using an array for better readability and management
    local packages=(
        gnome-calendar gnome-contacts gnome-weather gnome-clocks
        gnome-maps gnome-calculator gnome-notes evince eog totem
        gnome-music gnome-photos gnome-todo gnome-sound-recorder
        brave-browser evolution libreoffice-fresh poppler
        gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad
        gst-plugins-ugly gst-libav ffmpeg file-roller unzip zip p7zip
        base-devel git wget curl nano vim htop neofetch
        ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji
        networkmanager bluez bluez-utils cups \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    )
    pacman -S --noconfirm "${packages[@]}"
}

setup_services() {
    log_info "Configuring network, audio, and printing..."
#    pacman -S --noconfirm #dont need too run everytime??
    systemctl enable NetworkManager .service
    systemctl enable bluetooth.service
    systemctl enable cups.service
}

setup_user() {
    read -p "Enter username: " username
    if id "$username" &>/dev/null; then
        log_warn "User $username already exists. Skipping creation."
    else
        useradd -m -G wheel,audio,video,storage,optical -s /bin/bash "$username"
        log_info "Set password for $username:"
        passwd "$username"
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    fi
}

# --- Main Execution ---
main() {
    check_requirements
    update_system
    install_productivity
    setup_services
    setup_user
    
    log_info "Installation complete! Please review logs before rebooting."
}

main "$@"