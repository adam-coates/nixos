{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./autocmds.nix
    ./theme.nix
    ./lsp.nix
    ./completion.nix
    ./treesitter.nix
    ./telescope.nix
    ./formatting.nix
    ./linting.nix
    ./git.nix
    ./ui.nix
    ./dap.nix
    ./markdown.nix
    ./extra.nix
  ];

  programs.nixvim = {
    enable = true;

    # Set leader keys BEFORE any keymaps are registered
    extraConfigLuaPre = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = ","
    '';

    # Globals
    globals = {
      mapleader = " ";
      maplocalleader = ",";

      # nvim-tree: disable netrw
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;

      # gruvbox-material settings
      gruvbox_material_foreground = "material";
      gruvbox_material_background = "original";
      gruvbox_material_float_style = "blend";
      gruvbox_material_statusline_style = "original";
      gruvbox_material_cursor = "auto";
    };

    # Raw Lua files loaded via extraFiles
    extraFiles = {
      "lua/globals.lua".source = ./lua/globals.lua;
      "lua/ui/statusline.lua".source = ./lua/statusline.lua;
    };

    # Load globals and statusline from init
    extraConfigLuaPost = ''
      require("globals")
      require("ui.statusline")
    '';

    # Extra plugins not in nixvim
    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      plenary-nvim
      vim-tmux-navigator
    ];
  };
}
