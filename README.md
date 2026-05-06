# NixOS Config

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

The installer partitions the selected disk (GPT: 512 MB EFI, 4 GB swap, rest ext4), generates hardware config, runs `nixos-install`, and sets up user passwords.

## Structure

```
.
├── flake.nix                         # Entry point (nixpkgs, home-manager, nixvim)
├── install.sh                        # Automated disk partition + install
├── hosts/adam/
│   ├── default.nix                   # System config (boot, users, services, fonts, VPN, printing)
│   ├── hardware-configuration.nix
│   └── gaming.nix                    # Gaming / virtualization
├── modules/
│   └── colorscheme/
│       └── gruvbox.nix               # Gruvbox color palette (dark + light)
├── home/
│   ├── default.nix                   # Home Manager entry, theme options, packages
│   ├── hyprland/
│   │   ├── default.nix               # Hyprland WM config + keybinds
│   │   └── hypridle.conf             # Idle timeouts (lock, dpms, suspend)
│   ├── quickshell/
│   │   ├── default.nix               # Quickshell service + helper scripts
│   │   ├── qml/                      # QML widgets (bar, launcher, panels, lock screen)
│   │   └── easyeffects/              # Audio presets 
│   ├── shell/
│   │   ├── bash.nix                  # Aliases (eza, bat, zoxide)
│   │   ├── ghostty.nix               # Terminal
│   │   ├── tmux.nix                  # Multiplexer + pomodoro + git status
│   │   └── starship.nix              # Prompt
│   ├── programs/
│   │   ├── common.nix                # fzf, direnv, git
│   │   ├── firefox.nix               # Hardened Firefox + extensions
│   │   └── zathura.nix               # PDF viewer
│   ├── hardware/
│   │   └── solaar.nix                # Logitech wireless
│   └── scripts/                      # Theme switch, lock, idle toggle, Inkscape integration
└── nixvim/                           # Neovim config via nixvim
    ├── keymaps.nix
    ├── lsp.nix
    ├── completion.nix
    ├── treesitter.nix
    ├── telescope.nix
    ├── formatting.nix / linting.nix
    ├── git.nix / dap.nix
    ├── markdown.nix
    └── lua/                          # Statusline, Zotero annotations
```

## Keybinds

| Key                 | Action                                      |
| ------------------- | ------------------------------------------- |
| `Super + Return`    | Terminal (ghostty)                          |
| `Super + R`         | Launcher (quickshell)                       |
| `Super + E`         | File manager (thunar)                       |
| `Super + Q`         | Kill window                                 |
| `Super + F`         | Fullscreen                                  |
| `Super + V`         | Toggle floating                             |
| `Super + J`         | Toggle split                                |
| `Super + P`         | Pseudo                                      |
| `Super + C`         | Clipboard history                           |
| `Super + .`         | Emoji picker                                |
| `Super + T`         | Todoist                                     |
| `Super + I`         | Inkscape stylinator                         |
| `` Super + ` ``     | Triggers panel                              |
| `Super Shift + T`   | Toggle light/dark theme                     |
| `Super Shift + P`   | Power menu                                  |
| `Super Shift + L`   | Lock screen                                 |
| `Super Shift + S`   | Screenshot (save to ~/Pictures/screenshots) |
| `Super Shift + X`   | Toggle voice dictation                      |
| `Print`             | Screenshot (select area → swappy editor)    |
| `Super + 1-0`       | Switch workspace                            |
| `Super Shift + 1-0` | Move window to workspace                    |
| Media keys          | Volume, brightness, play/pause, next/prev   |

## Theming

Colors defined in `modules/colorscheme/gruvbox.nix`, propagated via `theme.colors` in `home/default.nix`. Light specialisation available — toggle with `Super Shift + T`.

Primary font set via `theme.font` in `home/default.nix`:

```nix
theme.font = "TX02 Nerd Font";
```

Cursor: Bibata-Modern-Classic · Icons: Gruvbox-Dark · GTK: adw-gtk3-dark

### Installing a custom/paid font

Install font files to `~/.local/share/fonts/`, update `theme.font` in `home/default.nix` and `fontFamily` in `home/quickshell/qml/Theme.qml`, then rebuild.

## Quickshell

Custom status bar and desktop shell built with QML:

- **Bar:** Clock, workspaces, system tray, battery gauge, idle/dictation indicators
- **Panels:** Audio, network, Bluetooth, clipboard, Todoist, stylinator (Inkscape)
- **Overlays:** Launcher with file preview, emoji picker, notifications, lock screen, power menu
- **Audio:** EasyEffects presets 

## System Services

- **Display:** ly · **Audio:** PipeWire + PulseAudio + ALSA · **Bluetooth:** BlueZ + Blueman
- **VPN:** OpenConnect (SSO) + WireGuard via NetworkManager
- **Printing:** CUPS + Avahi mDNS + Epson USB
- **Virtualization:** libvirtd + virt-manager + QEMU/SPICE
- **Power:** power-profiles-daemon + upower · **Idle:** hypridle (5 min lock, 30 min suspend)
- **Startup:** nm-applet, cliphist, solaar, voxtype, nextcloud

## Neovim

Configured via [nixvim](https://github.com/nix-community/nixvim) in `nixvim/`. LSP, Treesitter, Telescope, DAP, completion, formatting, linting, git integration, markdown support, and Zotero annotation import.

## Rebuilding

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#adam
```
