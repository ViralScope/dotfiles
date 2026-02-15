#!/usr/bin/env bash
set -e

echo "== Installing packages =="
sudo pacman -S --needed --noconfirm \
    dunst \
    wofi \
    hyprpolkitagent \
    cachyos-gaming-meta \
    steam \
    hyprpaper \
    waybar

echo "== Cloning dotfiles =="

REPO_DIR="$HOME/dotfiles"

if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/ViralScope/dotfiles.git "$REPO_DIR"
else
    echo "Dotfiles already exist. Pulling latest changes..."
    git -C "$REPO_DIR" pull || true
fi

mkdir -p "$HOME/Pictures"
cp -f "$REPO_DIR/hello.jpg" "$HOME/Pictures/" 2>/dev/null || true

mkdir -p "$HOME/.config"

if [ -d "$REPO_DIR/.config" ]; then
    for dir in dunst hypr kitty wofi waybar; do
        if [ -d "$REPO_DIR/.config/$dir" ]; then
            cp -r "$REPO_DIR/.config/$dir" "$HOME/.config/"
            echo "Copied $dir"
        else
            echo "Skipped $dir (not found in repo)"
        fi
    done
else
    echo ".config directory not found in repository."
fi


echo "== Enabling BBR + CAKE sysctl config =="
sudo tee /etc/sysctl.d/99-cachy-networking.conf > /dev/null <<EOF
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
EOF

sudo sysctl --system

echo "== Disabling ananicy-cpp =="
sudo systemctl disable --now ananicy-cpp || true

echo "== Applying CAKE to active interface =="
IFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -n "$IFACE" ]; then
    sudo tc qdisc replace dev "$IFACE" root cake || true
    echo "Applied CAKE on $IFACE"
else
    echo "Could not detect active interface."
fi

echo "== Activating ADIOS on NVMe drives (if supported) =="

for dev in /sys/block/nvme*n*; do
    if [ -f "$dev/queue/scheduler" ]; then
        if grep -q adios "$dev/queue/scheduler"; then
            echo adios | sudo tee "$dev/queue/scheduler"
            echo "ADIOS set on $(basename $dev)"
        else
            echo "ADIOS not available on $(basename $dev)"
        fi
    fi
done

echo "== Making ADIOS persistent via udev rule =="

sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null <<EOF
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="adios"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

echo "== Setup Complete =="
echo "Reboot recommended."
