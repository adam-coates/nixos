{ pkgs, ... }:

let
  gruvbox = import ./modules/colorscheme/gruvbox.nix;

  mkTheme = c: ''
    set-option -g status-style "fg=#${c.fg},bg=default"

    set-option -g status-left "\
    #[fg=#${c.gray},bg=default,bold]\
    #[fg=#${c.bg},bg=#${c.gray},bold]#S \
    #[fg=#${c.gray},bg=default]\
    "

    set-option -g status-right "#{pomodoro_status}#($HOME/.tmux/scripts/git-status.sh #{pane_current_path})#($HOME/.tmux/scripts/wb-git-status.sh #{pane_current_path} &)"

    set-option -g window-status-format "\
    #[bg=default] \
    #[fg=#${c.gray},bg=default]#I\
    #[fg=#${c.purple},bg=default]:\
    #[fg=#${c.gray},bg=default]#W\
     \
    "

    set-option -g window-status-current-format "\
    #[fg=#${c.gray},bg=default]\
    #[fg=#${c.bg},bg=#${c.gray}]#I\
    #[fg=#${c.purple}]:\
    #[fg=#${c.bg}]#W\
    #[fg=#${c.gray},bg=default]\
    "

    set-option -g window-status-separator ""
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
