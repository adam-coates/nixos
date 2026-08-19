{ pkgs, ... }:

{
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    settings = {
      # `prettierd` rather than `prettier`: only the daemon is packaged in
      # extraPackages below, and conform resolves formatters by binary name --
      # naming "prettier" here silently skipped every one of these filetypes.
      formatters_by_ft = {
        javascript = [ "prettierd" ];
        typescript = [ "prettierd" ];
        javascriptreact = [ "prettierd" ];
        typescriptreact = [ "prettierd" ];
        svelte = [ "prettierd" ];
        css = [ "prettierd" ];
        html = [ "prettierd" ];
        json = [ "prettierd" ];
        yaml = [ "prettierd" ];
        markdown = [ "prettierd" ];
        graphql = [ "prettierd" ];
        liquid = [ "prettierd" ];
        lua = [ "stylua" ];
        python = [
          "isort"
          "black"
        ];
        nix = [ "nixfmt" ];
      };

      format_on_save = {
        lsp_format = "fallback";
        async = false;
        timeout_ms = 3000;
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>mp";
      action.__raw = ''
        function()
          require("conform").format({
            lsp_format = "fallback",
            async = false,
            timeout_ms = 1000,
          })
        end
      '';
      options.desc = "Format file or range (in visual mode)";
    }
  ];

  # Make formatters available.
  #
  # black and isort are deliberately absent: they are pinned per project via
  # that project's flake. Since `extraPackages` is prefixed onto nvim's PATH,
  # listing them here would override the devshell version and let nvim format
  # differently to CI.
  programs.nixvim.extraPackages = with pkgs; [
    prettierd
    stylua
    nixfmt
  ];
}
