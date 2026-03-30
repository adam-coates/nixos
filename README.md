# Adam's NixOS Config

Hyprland · Quickshell · Ghostty · Neovim

## Fresh Install

```bash
# Boot NixOS minimal ISO, then:
sudo -i
git clone https://github.com/adam-coates/nixos
mv nixos/ nixos-config/
cd nixos-config
chmod +x install.sh
./install.sh
```

## Structure

```
.
├── flake.nix                         # Entry point, pins dependencies
├── install.sh                        # Automated install script
├── hosts/
│   └── adam/
│       ├── default.nix               # System config (bootloader, users, services, fonts)
│       └── hardware-configuration.nix
├── modules/
│   ├── fonts.nix                     # Font configuration
│   └── colorscheme/
│       └── gruvbox.nix               # Gruvbox color palette (dark + light)
├── home/
│   ├── default.nix                   # Home Manager entry point, theme options
│   ├── hyprland/                     # Hyprland WM config + keybinds
│   ├── quickshell/                   # Status bar, launcher, notifications, lock screen
│   │   └── qml/                      # QML source (Theme.qml, widgets, etc.)
│   ├── walker/                       # App launcher config + theme
│   ├── shell/
│   │   ├── ghostty.nix               # Terminal
│   │   ├── tmux.nix                  # Multiplexer
│   │   ├── bash.nix
│   │   └── starship.nix              # Prompt
│   ├── programs/
│   │   ├── firefox.nix
│   │   └── zathura.nix               # PDF viewer
│   └── hardware/                     # Hardware-specific (Solaar, etc.)
└── nixvim/                           # Neovim config via nixvim
```

## Keybinds

| Key                 | Action                                      |
| ------------------- | ------------------------------------------- |
| `SUPER + Return`    | Open terminal (ghostty)                     |
| `SUPER + R`         | Open launcher (quickshell)                  |
| `SUPER + E`         | File manager (thunar)                       |
| `SUPER + Q`         | Kill window                                 |
| `SUPER + F`         | Fullscreen                                  |
| `SUPER + V`         | Toggle floating                             |
| `SUPER + J`         | Toggle split                                |
| `SUPER + C`         | Clipboard history                           |
| `SUPER + .`         | Emoji picker                                |
| `SUPER + \``        | Triggers panel                              |
| `SUPER SHIFT + T`   | Toggle light/dark theme                     |
| `SUPER SHIFT + P`   | Power menu                                  |
| `SUPER SHIFT + L`   | Lock screen                                 |
| `SUPER SHIFT + S`   | Screenshot (save to ~/Pictures/screenshots) |
| `SUPER SHIFT + X`   | Toggle voice dictation                      |
| `Print`             | Screenshot (select area → swappy editor)    |
| `SUPER + 1-0`       | Switch workspace                            |
| `SUPER SHIFT + 1-0` | Move window to workspace                    |

## Theming

Colors are defined in `modules/colorscheme/gruvbox.nix` and propagated via the `theme.colors` option in `home/default.nix`. A light specialisation is available.

The primary font is set via `theme.font` in `home/default.nix`:

```nix
theme.font = "JetBrainsMono Nerd Font";
```

### Installing a custom/paid font

After first boot, install font files to `~/.local/share/fonts/`, then update `theme.font` in `home/default.nix` and `fontFamily` in `home/quickshell/qml/Theme.qml` to match the font name, then rebuild.

## Rebuilding

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#adam
```

## Neovim

Configured via [nixvim](https://github.com/nix-community/nixvim) in the `nixvim/` directory.
