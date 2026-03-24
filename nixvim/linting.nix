{ pkgs, ... }:

{
  programs.nixvim.plugins.lint = {
    enable = true;

    lintersByFt = {
      # python linting commented out in original config
    };

    autoCmd = {
      event = [ "BufEnter" "BufWritePost" "InsertLeave" ];
      callback.__raw = ''
        function()
          require("lint").try_lint()
        end
      '';
    };
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>l";
      action.__raw = ''
        function()
          require("lint").try_lint()
        end
      '';
      options.desc = "Trigger linting for current file";
    }
  ];

  # Linter packages
  programs.nixvim.extraPackages = with pkgs; [
    eslint_d
    shellcheck
    markdownlint-cli
    yamllint
    nodePackages.jsonlint
    htmlhint
    ruff
    mypy
  ];
}
