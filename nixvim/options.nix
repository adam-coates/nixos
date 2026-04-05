{ ... }:

{
  programs.nixvim.opts = {
    # Spelling
    spelllang = "en_gb";
    spell = true;
    encoding = "utf-8";
    fileencoding = "utf-8";

    # Line numbers
    relativenumber = true;
    number = true;

    # Tabs & indentation
    tabstop = 4;
    shiftwidth = 4;
    expandtab = true;
    autoindent = true;

    # Line wrapping
    wrap = false;

    # Search settings
    ignorecase = true;
    smartcase = true;

    # Cursor line
    cursorline = true;

    # Sign column (always show for diagnostics/git signs)
    signcolumn = "yes";

    # Appearance
    termguicolors = true;

    # Backspace
    backspace = "indent,eol,start";

    # Clipboard
    clipboard = "unnamedplus";

    # Split windows
    splitright = true;
    splitbelow = true;

    # Scroll offset
    scrolloff = 8;

    # Undo
    swapfile = false;
    backup = false;
    undofile = true;

    # Folding
    foldenable = true;
    foldlevel = 99;
    foldmethod = "expr";
    foldexpr = "v:lua.vim.treesitter.foldexpr()";
    foldtext = "";
    foldcolumn = "0";

    # Window border
    winborder = "single";

    # Command height
    cmdheight = 0;
  };

  programs.nixvim.extraConfigLua = ''
    vim.opt.iskeyword:append("-")
    vim.opt.fillchars:append({fold = " "})
    vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

    -- Prefer LSP folding if client supports it
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method('textDocument/foldingRange') then
          local win = vim.api.nvim_get_current_win()
          vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
        end
      end,
    })
  '';
}
