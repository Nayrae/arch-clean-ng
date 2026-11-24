#!/usr/bin/env bash
# kali-clean-ng installer for Arch Linux: i3 + alacritty + tmux + rofi + picom + zsh + nvim
# Run from a normal (non-root) user:  ./install.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

if [ "$EUID" -eq 0 ]; then
    echo "Run this as your normal user, not root (sudo is used where needed)." >&2
    exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
    echo "pacman not found: this installer is for Arch Linux (and Arch-based distros)." >&2
    exit 1
fi

# ---------------------------------------------------------------- packages
# Full upgrade together with the install: partial upgrades are unsupported on Arch
info "Updating system and installing packages"
sudo pacman -Syu --needed --noconfirm \
    base-devel wget curl git unzip rsync perl psmisc thunar \
    xorg-server xorg-xinit xorg-xrandr xorg-setxkbmap \
    i3-wm i3blocks i3status i3lock rofi feh picom unclutter \
    alacritty kitty tmux zsh neovim lazygit xclip ripgrep fd fzf zoxide \
    arandr flameshot papirus-icon-theme lxappearance imagemagick \
    sysstat python-pipx fontconfig ttf-iosevka-nerd ttf-roboto-mono-nerd

# VMware guest tools (shared clipboard / auto-resize) only when running in VMware
if [ "$(systemd-detect-virt 2>/dev/null || true)" = "vmware" ]; then
    info "VMware detected: installing open-vm-tools"
    sudo pacman -S --needed --noconfirm open-vm-tools gtkmm3
    sudo systemctl enable --now vmtoolsd.service vmware-vmblock-fuse.service || true
fi

# Arc theme is only in the AUR on Arch
AUR_HELPER=""
for h in paru yay; do command -v "$h" >/dev/null 2>&1 && { AUR_HELPER="$h"; break; }; done
if [ -n "$AUR_HELPER" ]; then
    info "Installing arc-gtk-theme from the AUR with $AUR_HELPER"
    "$AUR_HELPER" -S --needed --noconfirm arc-gtk-theme || warn "arc-gtk-theme install failed (optional)"
else
    warn "No AUR helper (paru/yay) found: install 'arc-gtk-theme' from the AUR yourself for the Arc-Dark theme"
fi

# ---------------------------------------------------------------- i3blocks scripts
# i3blocks.conf uses ~/.config/i3/blocks/<block>; Arch's i3blocks package ships no scripts
info "Installing i3blocks-contrib scripts"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone --depth 1 https://github.com/vivien/i3blocks-contrib "$tmp/contrib"
mkdir -p ~/.config/i3/blocks
for b in cpu_usage memory disk bandwidth; do
    install -m 755 "$tmp/contrib/$b/$b" ~/.config/i3/blocks/$b
done

# Nerd Fonts (Iosevka, RobotoMono) come from the ttf-*-nerd packages above
fc-cache -f

# ---------------------------------------------------------------- shell / tools
if [ ! -d ~/.oh-my-zsh ]; then
    info "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ ! -d ~/.local/share/tmux/oh-my-tmux ]; then
    info "Installing oh-my-tmux"
    git clone --depth 1 https://github.com/gpakosz/.tmux.git ~/.local/share/tmux/oh-my-tmux
fi
mkdir -p ~/.config/tmux
ln -sfn ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf

info "Installing pywal"
pipx install pywal || warn "pywal install failed (optional)"
pipx ensurepath >/dev/null 2>&1 || true

# ---------------------------------------------------------------- dotfiles
# Existing files are moved to $BACKUP before being replaced
deploy() {
    local src="$REPO/$1" dst="$HOME/$1"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP/$(dirname "$1")"
        mv "$dst" "$BACKUP/$1"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
}

info "Copying dotfiles (backups go to $BACKUP)"
for f in \
    .config/i3/config \
    .config/i3/i3blocks.conf \
    .config/i3/clipboard_fix.sh \
    .config/i3/cpu_graph.sh \
    .config/alacritty/alacritty.toml \
    .config/picom/picom.conf \
    .config/rofi/config.rasi \
    .config/rofi/tokyo.rasi \
    .config/tmux/tmux.conf.local \
    .config/flameshot/flameshot.ini \
    .config/nvim \
    .zshrc \
    .fehbg \
    .wallpaper; do
    deploy "$f"
done
chmod +x ~/.config/i3/clipboard_fix.sh ~/.config/i3/cpu_graph.sh ~/.fehbg

# Without a display manager, start i3 with startx
if ! systemctl is-enabled display-manager.service >/dev/null 2>&1; then
    info "No display manager enabled: writing ~/.xinitrc so 'startx' launches i3"
    if [ -e ~/.xinitrc ]; then
        mkdir -p "$BACKUP"
        mv ~/.xinitrc "$BACKUP/.xinitrc"
    fi
    printf '#!/bin/sh\nexec i3\n' > ~/.xinitrc
    chmod +x ~/.xinitrc
    NO_DM=1
fi

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
    info "Setting zsh as default shell"
    sudo chsh -s "$(command -v zsh)" "$USER"
fi

echo
info "Done!"
if [ "${NO_DM:-0}" = 1 ]; then
    echo "  - Reboot, log in on the TTY and run 'startx' to start i3"
    echo "    (or install and enable a display manager, e.g. lightdm + lightdm-gtk-greeter)."
else
    echo "  - Reboot / log out and pick i3 on the login screen."
fi
echo "  - Run lxappearance and select Arc-Dark (icons: Papirus)."
echo "  - Neovim plugins (LazyVim) install themselves on first 'nvim' launch."
echo "  - The i3 config sets an Italian keyboard (setxkbmap it); change it in ~/.config/i3/config if needed."
echo "  - Optional: 'wal -i <image>' to generate a colour scheme; edit ~/.fehbg to change the wallpaper."
if [ -d "$BACKUP" ]; then echo "  - Your previous files were saved in $BACKUP"; fi
