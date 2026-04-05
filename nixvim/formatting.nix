{ pkgs, ... }:

{
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    settings = {
      formatters_by_ft = {
        javascript = [ "prettier" ];
        typescript = [ "prettier" ];
        javascriptreact = [ "prettier" ];
        typescriptreact = [ "prettier" ];
        svelte = [ "prettier" ];
        css = [ "prettier" ];
        html = [ "prettier" ];
        json = [ "prettier" ];
        yaml = [ "prettier" ];
        markdown = [ "prettier" ];
        graphql = [ "prettier" ];
        liquid = [ "prettier" ];
        lua = [ "stylua" ];
        python = [ "isort" "black" ];
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
      mode = [ "n" "v" ];
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

  # Make formatters available
  programs.nixvim.extraPackages = with pkgs; [
    prettierd
    stylua
    black
    isort
  ];
}
