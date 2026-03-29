{ pkgs, ... }:

let
  git-status-script = pkgs.writeShellScript "git-status.sh" (builtins.readFile ../scripts/tmux/git-status.sh);
  wb-git-status-script = pkgs.writeShellScript "wb-git-status.sh" (builtins.readFile ../scripts/tmux/wb-git-status.sh);

  tmux-pomodoro-plus = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-pomodoro-plus";
    rtpFilePath = "pomodoro.tmux";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "olimorris";
      repo = "tmux-pomodoro-plus";
      rev = "master";
      sha256 = "002r406xvg6yjwx904nd5aik7xs4bs7vcwdbbpjd7jw0djmxysd5";
    };
  };
in
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.bash}/bin/bash";
    prefix = "C-b";
    baseIndex = 1;
    escapeTime = 0;
    mouse = true;
    clock24 = true;
    historyLimit = 10000;
    keyMode = "vi";
    terminal = "\${TERM}";
    sensibleOnTop = false;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      vim-tmux-navigator
    ] ++ [ tmux-pomodoro-plus ];

    extraConfig = ''
      # Pane base index
      setw -g pane-base-index 1

      # Splits
      unbind %
      bind | split-window -h
      unbind '"'
      bind - split-window -v

      # Reload config
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf

      # Pane resizing
      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5
      bind -r m resize-pane -Z

      # Vi copy mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection

      # Window management
      set -g allow-rename on
      set -g renumber-windows on

      # Terminal features
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
      set -as terminal-features ",*:RGB"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Window titles
      set -g set-titles on

      # Activity
      setw -g monitor-activity off
      set -g bell-action any
      set -g visual-bell off
      set -g visual-activity off
      set -g focus-events on
      setw -g aggressive-resize on
      set -g detach-on-destroy off

      # Passthrough
      set -gq allow-passthrough on
      set-option -g allow-passthrough on

      # Resurrect & Continuum
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'

      # Pomodoro
      set -g @pomodoro_granularity 'on'
      set -g status-interval 1
      set -g @pomodoro_on "#[fg=magenta]  "
      set -g @pomodoro_complete "#[fg=green] "
      set -g @pomodoro_pause "#[fg=yellow] ⏸︎ "
      set -g @pomodoro_prompt_break "#[fg=cyan]🕤 ? "
      set -g @pomodoro_prompt_pomodoro "#[fg=brightblack]🕤 ? "

      # ── Status line ────────────────────────────────────────────────────
      set-option -g status "on"

      # Nerdfont characters
      HALF_ROUND_OPEN=""
      HALF_ROUND_CLOSE=""
      TRIANGLE_OPEN=""
      TRIANGLE_CLOSE=""

      set-option -g status-style "fg=default,bg=default"
      set-option -g status-justify centre

      # Left section
      set-option -g status-left "\
      #[fg=grey,bg=default,bold]''${HALF_ROUND_OPEN}\
      #[fg=black,bg=grey,bold]#S \
      #[fg=grey,bg=default]''${TRIANGLE_CLOSE}\
      "

      # Git status widgets
      git_status="#(${git-status-script} #{pane_current_path})"
      wb_git_status="#(${wb-git-status-script} #{pane_current_path} &)"

      # Right section
      set-option -g status-right "#{pomodoro_status}$git_status$wb_git_status"

      set-option -g status-left-length 100
      set-option -g status-right-length 150

      # Inactive windows
      set-option -g window-status-format "\
      #[bg=default] \
      #[fg=brightblack,bg=default]#I\
      #[fg=magenta,bg=default]:\
      #[fg=brightblack,bg=default]#W\
       \
      "

      # Active window
      set-option -g window-status-current-format "\
      #[fg=grey,bg=default]''${HALF_ROUND_OPEN}\
      #[fg=black,bg=grey]#I\
      #[fg=magenta]:\
      #[fg=black]#W\
      #[fg=grey,bg=default]''${HALF_ROUND_CLOSE}\
      "

      set-option -g window-status-separator ""

      # Pane borders
      set -g pane-border-style "fg=brightblack"
      set -g pane-active-border-style "fg=blue"
      set -g message-style "bg=default,fg=blue"
      set -g message-command-style "bg=default,fg=blue"
      set -g mode-style "bg=blue,fg=black"
      setw -g clock-mode-colour blue
    '';
  };
}
