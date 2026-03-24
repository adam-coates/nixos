{ pkgs, ... }:

{
  programs.nixvim = {
    colorschemes.gruvbox-material.enable = true;

    # Additional colorscheme plugins (available for hot-reload)
    extraPlugins = with pkgs.vimPlugins; [
      bamboo-nvim
      catppuccin-nvim
      everforest
      flexoki-neovim
      kanagawa-nvim
      nord-nvim
      rose-pine
      tokyonight-nvim
    ];

    # Transparency overrides
    highlightOverride = {
      Normal = { bg = "none"; };
      NormalFloat = { bg = "none"; };
      FloatBorder = { bg = "none"; };
      Pmenu = { bg = "none"; };
      Terminal = { bg = "none"; };
      EndOfBuffer = { bg = "none"; };
      FoldColumn = { bg = "none"; };
      Folded = { bg = "none"; };
      SignColumn = { bg = "none"; };
      NormalNC = { bg = "none"; };
      WhichKeyFloat = { bg = "none"; };
      TelescopeBorder = { bg = "none"; };
      TelescopeNormal = { bg = "none"; };
      TelescopePromptBorder = { bg = "none"; };
      TelescopePromptTitle = { bg = "none"; };
      NvimTreeNormal = { bg = "none"; };
      NvimTreeVertSplit = { bg = "none"; };
      NvimTreeEndOfBuffer = { bg = "none"; };
      NeoTreeNormal = { bg = "none"; };
      NeoTreeNormalNC = { bg = "none"; };
      NeoTreeVertSplit = { bg = "none"; };
      NeoTreeWinSeparator = { bg = "none"; };
      NeoTreeEndOfBuffer = { bg = "none"; };
      NotifyINFOBody = { bg = "none"; };
      NotifyERRORBody = { bg = "none"; };
      NotifyWARNBody = { bg = "none"; };
      NotifyTRACEBody = { bg = "none"; };
      NotifyDEBUGBody = { bg = "none"; };
      NotifyINFOTitle = { bg = "none"; };
      NotifyERRORTitle = { bg = "none"; };
      NotifyWARNTitle = { bg = "none"; };
      NotifyTRACETitle = { bg = "none"; };
      NotifyDEBUGTitle = { bg = "none"; };
      NotifyINFOBorder = { bg = "none"; };
      NotifyERRORBorder = { bg = "none"; };
      NotifyWARNBorder = { bg = "none"; };
      NotifyTRACEBorder = { bg = "none"; };
      NotifyDEBUGBorder = { bg = "none"; };
    };
  };
}
