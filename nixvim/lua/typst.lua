local function git_root()
  local dir = vim.fn.finddir(".git", vim.fn.expand("%:p:h") .. ";")
  if dir ~= "" then
    return vim.fn.fnamemodify(dir, ":h")
  end
  return vim.fn.getcwd()
end

local function typst_watch()
  local root = git_root()
  local file = vim.fn.expand("%:.")

  vim.cmd("vsplit")
  vim.cmd("vertical resize 20")
  vim.cmd("terminal typst watch --root " .. vim.fn.fnameescape(root) .. " " .. vim.fn.fnameescape(file))
  vim.cmd("wincmd h")
end

local function typst_preview()
  local pdf = vim.fn.expand("%:p:r") .. ".pdf"
  vim.fn.jobstart({ "zathura", "--fork", pdf }, { detach = true })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }
    vim.keymap.set("n", "<leader>tw", typst_watch, vim.tbl_extend("force", opts, { desc = "Typst watch (compile)" }))
    vim.keymap.set("n", "<leader>tp", typst_preview, vim.tbl_extend("force", opts, { desc = "Typst preview PDF" }))
  end,
})
