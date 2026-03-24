{ pkgs, lib, ... }:

let
  mkTheme = pname: src: pkgs.vimUtils.buildVimPlugin {
    inherit pname src;
    version = "unstable";
  };

  bamboo-nvim = mkTheme "bamboo-nvim" (pkgs.fetchFromGitHub {
    owner = "ribru17"; repo = "bamboo.nvim"; rev = "master";
    sha256 = "000bz7z7ghwaav2vbdynzp1h3rg0dy62wdp8g631b5hk1x1apljz";
  });

  flexoki-neovim = mkTheme "flexoki-neovim" (pkgs.fetchFromGitHub {
    owner = "kepano"; repo = "flexoki-neovim"; rev = "main";
    sha256 = "0j6r1rm9g6mm5b5x2wddwyhh6wjagk0x9babs73ky081sgvlyl2f";
  });

  matteblack-nvim = mkTheme "matteblack-nvim" (pkgs.fetchFromGitHub {
    owner = "tahayvr"; repo = "matteblack.nvim"; rev = "main";
    sha256 = "0zbq1g5zmjq3sd9wdil7m5s0hvmvdby692k2vfa2m07lwx626kxn";
  });

  monokai-pro-nvim = mkTheme "monokai-pro-nvim" (pkgs.fetchFromGitHub {
    owner = "loctvl842"; repo = "monokai-pro.nvim"; rev = "master";
    sha256 = "175pjdjr6g6ajd44ddd26ckl9dgbljrfjd8d4zgjndpn80hqdjhv";
  });
in
{
  programs.nixvim = {
    colorschemes.gruvbox-material.enable = true;

    # Additional colorscheme plugins (available for hot-reload)
    extraPlugins = (with pkgs.vimPlugins; [
      catppuccin-nvim
      everforest
      kanagawa-nvim
      nord-nvim
      rose-pine
      tokyonight-nvim
    ]) ++ [
      bamboo-nvim
      flexoki-neovim
      matteblack-nvim
      monokai-pro-nvim
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
