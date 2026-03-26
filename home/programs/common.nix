{ ... }:

{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "adam-coates";
      email = ""; # add your email
    };
  };
}
