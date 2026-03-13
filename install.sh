#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "  ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗"
echo "  ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝"
echo "  ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗"
echo "  ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║"
echo "  ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║"
echo "  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "${GREEN}Adam's NixOS Installer${NC}"
echo ""

# Check we're running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo -i)${NC}"
    exit 1
fi

# ── Disk selection ────────────────────────────────────────────────────────────
echo -e "${YELLOW}Available disks:${NC}"
lsblk -d -o NAME,SIZE,MODEL
echo ""
read -p "Enter disk to install to (e.g. vda, sda): " DISK
DISK="/dev/$DISK"

echo ""
echo -e "${YELLOW}Partition layout:${NC}"
echo "  1 - EFI/boot  512MB"
echo "  2 - swap       4GB"
echo "  3 - root      rest"
echo ""
read -p "Proceed with wiping $DISK and repartitioning? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# ── Partitioning ──────────────────────────────────────────────────────────────
echo -e "${BLUE}Partitioning $DISK...${NC}"
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MB 512MB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary linux-swap 512MB 4608MB
parted "$DISK" -- mkpart primary ext4 4608MB 100%

# Wait for partitions
sleep 2

# Detect partition naming (nvme uses p1 p2, others use 1 2)
if [[ "$DISK" == *"nvme"* ]]; then
    BOOT="${DISK}p1"
    SWAP="${DISK}p2"
    ROOT="${DISK}p3"
else
    BOOT="${DISK}1"
    SWAP="${DISK}2"
    ROOT="${DISK}3"
fi

# ── Formatting ────────────────────────────────────────────────────────────────
echo -e "${BLUE}Formatting partitions...${NC}"
mkfs.fat -F 32 -n boot "$BOOT"
mkswap -L swap "$SWAP"
mkfs.ext4 -L nixos "$ROOT"

# Wait for labels to register
sleep 3
udevadm settle

# ── Mounting ──────────────────────────────────────────────────────────────────
echo -e "${BLUE}Mounting...${NC}"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/disk/by-label/swap

# ── Hardware config ───────────────────────────────────────────────────────────
echo -e "${BLUE}Generating hardware configuration...${NC}"
nixos-generate-config --root /mnt

# ── Copy nixos config ─────────────────────────────────────────────────────────
echo -e "${BLUE}Copying NixOS config...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Save generated hardware config
HWCONFIG=$(cat /mnt/etc/nixos/hardware-configuration.nix)

# Copy all nix files flat into /mnt/etc/nixos
cp "$SCRIPT_DIR"/*.nix /mnt/etc/nixos/
cp "$SCRIPT_DIR/flake.nix" /mnt/etc/nixos/flake.nix

# Restore hardware config (may have been overwritten)
echo "$HWCONFIG" >/mnt/etc/nixos/hardware-configuration.nix

mkdir -p /mnt/tmp
chmod 1777 /mnt/tmp

# ── Install ───────────────────────────────────────────────────────────────────
echo -e "${BLUE}Installing NixOS (first pass, generating flake.lock)...${NC}"
nixos-install --flake /mnt/etc/nixos#adam --no-root-passwd || true

echo -e "${BLUE}Installing NixOS (second pass)...${NC}"
nixos-install --flake /mnt/etc/nixos#adam --no-root-passwd

# ── Set passwords ─────────────────────────────────────────────────────────────
echo -e "${BLUE}Setting password for adam...${NC}"
nixos-enter --root /mnt -c 'passwd root'
nixos-enter --root /mnt -c 'passwd adam'

# ── Post-install: clone neovim dotfiles ───────────────────────────────────────
echo -e "${BLUE}Setting up neovim dotfiles...${NC}"
git clone https://github.com/adam-coates/dotfiles.git /mnt/home/adam/dotfiles ||
    echo -e "${YELLOW}Warning: could not clone neovim dotfiles, do this manually after boot${NC}"

# Copy just the nvim config to the correct location
if [ -d "/mnt/home/adam/dotfiles/.config/nvim" ]; then
    mkdir -p /mnt/home/adam/.config
    cp -r /mnt/home/adam/dotfiles/.config/nvim /mnt/home/adam/.config/nvim
    echo -e "${GREEN}Neovim config copied successfully${NC}"
else
    echo -e "${YELLOW}Warning: could not find .config/nvim in dotfiles repo${NC}"
fi

# Fix ownership
chown -R 1000:1000 /mnt/home/adam/.config 2>/dev/null || true

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Things to do after first boot:${NC}"
echo "  1. Set your password:       passwd adam"
echo "  2. Add a wallpaper to:      ~/Pictures/ and update hyprpaper.conf"
echo "  3. Update git email in:     home/home.nix"
echo "  4. Update timezone in:      hosts/default/configuration.nix"
echo "  5. Move config to dotfiles: cp -r /etc/nixos ~/.config/nixos"
echo "  6. Rebuild anytime with:    sudo nixos-rebuild switch --flake ~/.config/nixos#adam"
echo ""
read -p "Reboot now? (yes/no): " REBOOT
if [ "$REBOOT" == "yes" ]; then
    reboot
fi
