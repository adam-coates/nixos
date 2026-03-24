{ pkgs, ... }:

let
  gruvbox = import ./modules/colorscheme/gruvbox.nix;

  mkTheme = c: ''
    set -g pane-border-style "fg=#${c.bg1}"
    set -g pane-active-border-style "fg=#${c.blue}"
    set -g message-style "bg=default,fg=#${c.blue}"
    set -g message-command-style "bg=default,fg=#${c.blue}"
    set -g mode-style "bg=#${c.blue},fg=#${c.bg}"
    setw -g clock-mode-colour "#${c.blue}"
  '';
in
{
  home.packages = [ pkgs.tmux ];

  xdg.configFile."tmux/themes/gruvbox-dark.conf".text  = mkTheme gruvbox.dark;
  xdg.configFile."tmux/themes/gruvbox-light.conf".text = mkTheme gruvbox.light;
}
