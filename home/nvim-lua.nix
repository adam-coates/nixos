# Plain neovim with a hand-written Lua config.
#
# ~/.config/nvim is an *out-of-store* symlink into this repo (../nvim), so nvim
# sees a writable directory: `:Lazy sync`, lazy-lock.json, `:MasonInstall` etc.
# all land in the repo and edits take effect without a rebuild.
#
# Enabled by flipping `useNixvim = false` in ./default.nix. Flipping it back to
# true restores the nixvim config in ../nixvim; ~/.config/nvim is then unlinked
# by home-manager on the next rebuild, but ../nvim stays on disk untouched.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Tooling the Lua config expects to find on PATH. These are *suffixed* onto
  # nvim's PATH (unlike nixvim's extraPackages, which prefixes), so a project
  # devshell still wins for anything it provides -- which is the behaviour the
  # nixvim config went out of its way to arrange for ruff, mypy, black and isort.
  #
  # mason.nvim also prepends its own bin dir, so a mason-installed server wins
  # over the copy here. These are the nix-native fallback for when mason's
  # prebuilt binary does not run (see programs.nix-ld in hosts/adam) -- the set
  # mirrors the `ensure_installed` lists in nvim/lua/plugins/lsp/mason.lua.
  nvimTools = with pkgs; [
    # Language servers
    lua-language-server
    zls
    typescript-language-server
    rust-analyzer
    bash-language-server
    pyright
    vscode-langservers-extracted # cssls, html, jsonls, eslint
    yaml-language-server
    ltex-ls-plus
    tinymist
    nixd

    # Formatters
    stylua
    prettierd
    shfmt
    nixfmt

    # Linters
    eslint_d
    lua54Packages.luacheck
    shellcheck
    markdownlint-cli
    yamllint
    htmlhint

    # Misc
    lazygit
    ripgrep
    fd
    gcc # treesitter grammar compilation
    gnumake
    unzip
    nodejs # required by many plugins / mason-installed servers
    tree-sitter
    git
  ];

  # NOTE: deliberately not `programs.neovim`. That module always writes
  # ~/.config/nvim/init.lua itself, which collides with symlinking the whole
  # nvim directory below ("Error installing file '.config/nvim/init.lua'
  # outside $HOME"). Wrapping the package directly sidesteps it.
  neovim-wrapped = pkgs.symlinkJoin {
    name = "neovim-wrapped";
    paths = [ pkgs.neovim ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --suffix PATH : ${lib.makeBinPath nvimTools}
      ln -sf $out/bin/nvim $out/bin/vi
      ln -sf $out/bin/nvim $out/bin/vim
    '';
  };
in

{
  home.packages = [ neovim-wrapped ];

  # The out-of-store symlink itself. `mkOutOfStoreSymlink` records the path as a
  # *string*, so the target is never copied into /nix/store and stays writable.
  #
  # NOTE: this hardcodes the clone location. If this repo ever moves off
  # ~/nixos, update the path here.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/nvim";
}
