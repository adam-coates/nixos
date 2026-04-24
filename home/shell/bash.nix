{ ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      cd = "z";
      rebuild = "sudo nixos-rebuild switch --flake ~/.config/nixos#adam";
    };
    initExtra = ''
      eval "$(zoxide init bash)"
      export PATH="$HOME/.local/bin:$PATH"

      # Force tmux status refresh on directory change
      __tmux_refresh_on_cd() {
        if [[ -n "$TMUX" ]]; then
          tmux refresh-client -S 2>/dev/null
        fi
      }
      PROMPT_COMMAND="__tmux_refresh_on_cd;$PROMPT_COMMAND"
    '';
  };
}
