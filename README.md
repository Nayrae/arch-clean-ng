# Kali-Clean-NG

Updated version of [kali-clean](https://github.com/xct/kali-clean): an i3 desktop for **Arch Linux** with alacritty, tmux (oh-my-tmux), rofi (Tokyo Night), picom, zsh (oh-my-zsh + fzf + zoxide) and Neovim (LazyVim).

## Installation

Clone the repo and run the installer as your normal user (not root):

```
./install.sh
```

Any files it replaces are backed up to `~/.dotfiles-backup/<timestamp>/`.

When it finishes, reboot and pick **i3** on the login screen. If no display manager is enabled, the installer writes `~/.xinitrc` instead, so log in on the TTY and run `startx`. Open a terminal (`super+Return`), run `lxappearance` and choose the Arc-Dark theme with Papirus icons. Arc is only in the AUR: the installer uses `paru` or `yay` if one is installed, otherwise install `arc-gtk-theme` yourself.

## What's included

| Path | What it is |
|---|---|
| `.config/i3/` | i3 config, i3blocks bar (with CPU graph), VMware clipboard fix |
| `.config/alacritty/alacritty.toml` | Alacritty config (TOML format) |
| `.config/rofi/` | `config.rasi` + `tokyo.rasi` theme |
| `.config/picom/picom.conf` | picom compositor (shadows, transparency) |
| `.config/tmux/tmux.conf.local` | oh-my-tmux local config with vi copy-mode |
| `.config/nvim/` | LazyVim starter config |
| `.config/flameshot/flameshot.ini` | Flameshot (`super+p`) |
| `.zshrc`, `.fehbg`, `.wallpaper/` | Shell config and wallpaper |

## Arch Linux port

- Packages come from `pacman -Syu --needed`, with no partial upgrades.
- compton was replaced by picom (`.config/picom/picom.conf`, picom >= 12 `rules` syntax), since Arch only ships picom.
- Nerd Fonts come from `ttf-iosevka-nerd` and `ttf-roboto-mono-nerd`, and fzf comes from the `fzf` package (`source <(fzf --zsh)`).
- i3blocks-contrib scripts go into `~/.config/i3/blocks/` instead of `/usr/share`, so pacman-managed paths stay untouched.
- The bandwidth block uses the default-route interface instead of a hard-coded `eth0`.
- open-vm-tools is installed only inside VMware, and the clipboard fix and `Virtual-1` xrandr mode do nothing elsewhere.

## Changes from kali-clean

- i3 now comes straight from apt, since gaps were merged into i3 4.22. Nothing is compiled anymore.
- Alacritty comes from apt and uses `alacritty.toml`. Alacritty 0.13 dropped the old `.yml` format.
- The rofi config uses the `.rasi` format.
- Nerd Fonts v3 are installed, and skipped if already present.
- Adds tmux, oh-my-tmux, Neovim with LazyVim, fzf, zoxide and lazygit.
- Installs pywal with pipx, because `pip3 install` is blocked on current Kali.
- Restores the i3blocks scripts that the Debian package no longer ships.

## Credits

Original setup by [xct](https://github.com/xct/kali-clean). Wallpaper by Wenqing Yan (https://www.yuumeiart.com/).
