{ pkgs, lib, ... }:

let
  tmuxPomodoroPlus = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-pomodoro-plus";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "olimorris";
      repo = "tmux-pomodoro-plus";
      rev = "main";
      sha256 = lib.fakeHash;
    };
  };
in
{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    prefix = "C-b";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "tmux-256color";
    resizeAmount = 5;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
      {
        plugin = tmuxPomodoroPlus;
        extraConfig = ''
          set -g @pomodoro_granularity 'on'
          set -g status-interval 1
          set -g @pomodoro_on "#[fg=magenta]  "
          set -g @pomodoro_complete "#[fg=green] "
          set -g @pomodoro_pause "#[fg=yellow] ⏸︎ "
          set -g @pomodoro_prompt_break "#[fg=cyan]🕤 ? "
          set -g @pomodoro_prompt_pomodoro "#[fg=brightblack]🕤 ? "
        '';
      }
    ];

    extraConfig = ''
      bind-key C-b send-prefix

      unbind %
      bind | split-window -h

      unbind '"'
      bind - split-window -v

      unbind r
      bind r source-file ~/.config/tmux/tmux.conf

      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5
      bind -r m resize-pane -Z

      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection

      set -g pane-base-index 1
      set -g allow-rename on
      set -g renumber-windows on
      set -g set-titles on
      set -g bell-action any
      set -g visual-bell off
      set -g visual-activity off
      set -g focus-events on
      set -g detach-on-destroy off
      set -gq allow-passthrough on
      setw -g monitor-activity off
      setw -g aggressive-resize on

      # Colors
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
      set -as terminal-features ",*:RGB"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Status bar
      HALF_ROUND_OPEN=""
      HALF_ROUND_CLOSE=""
      TRIANGLE_OPEN=""
      TRIANGLE_CLOSE=""

      set-option -g status "on"
      set-option -g status-style "fg=default,bg=default"
      set-option -g status-justify centre

      set-option -g status-left "\
      #[fg=grey,bg=default,bold]''${HALF_ROUND_OPEN}\
      #[fg=black,bg=grey,bold]#S \
      #[fg=grey,bg=default]''${TRIANGLE_CLOSE}\
      "

      SCRIPTS_PATH="$HOME/.tmux/scripts"
      set-option -g status-right "#{pomodoro_status}#($SCRIPTS_PATH/git-status.sh #{pane_current_path})#($SCRIPTS_PATH/wb-git-status.sh #{pane_current_path} &)"

      set-option -g status-left-length 100
      set-option -g status-right-length 150

      set-option -g window-status-format "\
      #[bg=default] \
      #[fg=brightblack,bg=default]#I\
      #[fg=magenta,bg=default]:\
      #[fg=brightblack,bg=default]#W\
       \
      "

      set-option -g window-status-current-format "\
      #[fg=grey,bg=default]''${HALF_ROUND_OPEN}\
      #[fg=black,bg=grey]#I\
      #[fg=magenta]:\
      #[fg=black]#W\
      #[fg=grey,bg=default]''${HALF_ROUND_CLOSE}\
      "

      set-option -g window-status-separator ""

      set -g pane-border-style "fg=brightblack"
      set -g pane-active-border-style "fg=blue"
      set -g message-style "bg=default,fg=blue"
      set -g message-command-style "bg=default,fg=blue"
      set -g mode-style "bg=blue,fg=black"
      setw -g clock-mode-colour blue
    '';
  };
}
