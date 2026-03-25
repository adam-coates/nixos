{ ... }:

{
  programs.nixvim = {
    colorschemes.gruvbox-material.enable = true;

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
    };
  };
}
