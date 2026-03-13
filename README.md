# Adam's NixOS Config

Hyprland · Waybar · Rofi · Ghostty · Mako · Neovim

## Fresh Install

```bash
# Boot NixOS minimal ISO, then:
sudo -i
nix-shell -p git
git clone https://github.com/adam-coates/nixos-config
cd nixos-config
chmod +x install.sh
./install.sh
```

## Structure

```
.
├── flake.nix                        # Entry point, pins dependencies
├── install.sh                       # Automated install script
├── hosts/
│   └── default/
│       ├── configuration.nix        # System config (bootloader, users, services)
│       └── hardware-configuration.nix  # Auto-generated, machine-specific
└── home/
    ├── home.nix                     # Home manager entry point
    ├── hyprland.nix                 # Hyprland WM config + keybinds
    ├── waybar.nix                   # Status bar
    ├── rofi.nix                     # App launcher
    ├── mako.nix                     # Notifications
    ├── ghostty.nix                  # Terminal
    └── hyprpaper.nix                # Wallpaper
```

## Keybinds

| Key | Action |
|-----|--------|
| `SUPER + Return` | Open terminal (ghostty) |
| `SUPER + R` | Open launcher (rofi) |
| `SUPER + E` | File manager (thunar) |
| `SUPER + Q` | Kill window |
| `SUPER + F` | Fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + 1-0` | Switch workspace |
| `SUPER + SHIFT + 1-0` | Move window to workspace |
| `SUPER + C` | Clipboard history |
| `Print` | Screenshot (select area) |

## Rebuilding

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#adam
```

## Neovim

Dotfiles are cloned from https://github.com/adam-coates/dotfiles into `~/.config/nvim` during install.
