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

  # Linter packages.
  #
  # `extraPackages` is *prefixed* onto nvim's PATH, so anything listed here wins
  # over a project devshell. ruff and mypy are deliberately absent: they are
  # pinned per project via that project's flake, and nvim should use whichever
  # version the devshell provides. (`extraPackagesAfter` would suffix instead,
  # if a global fallback is ever wanted.)
  programs.nixvim.extraPackages = with pkgs; [
    eslint_d
    shellcheck
    markdownlint-cli
    yamllint
    htmlhint
  ];
}
