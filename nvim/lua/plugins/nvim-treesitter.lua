return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ":TSUpdate",
  init = function()
    local parser_installed = {
      "python",
      "matlab",
      "json",
      "javascript",
      "typescript",
      "yaml",
      "html",
      "css",
      "markdown",
      "markdown_inline",
      "bash",
      "lua",
      "vim",
      "dockerfile",
      "gitignore",
      "r",
      "typst",
      "nix",
    }
    
    vim.defer_fn(function()
      require("nvim-treesitter").install(parser_installed)
    end, 1000)
    
    require("nvim-treesitter").update()
    
    -- auto-start highlights & indentation
    vim.api.nvim_create_autocmd("FileType", {
      desc = "User: enable treesitter highlighting",
      callback = function(ctx)
        -- highlights
        local hasStarted = pcall(vim.treesitter.start)
        -- indent
        local noIndent = {}
        if hasStarted and not vim.list_contains(noIndent, ctx.match) then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end
}
