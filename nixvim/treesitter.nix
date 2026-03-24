{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      settings = {
        highlight.enable = true;
        indent.enable = true;
      };

      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        python
        json
        javascript
        typescript
        yaml
        html
        css
        markdown
        markdown_inline
        bash
        lua
        vim
        dockerfile
        gitignore
        r
      ];
    };

    ts-autotag = {
      enable = true;
    };
  };
}
