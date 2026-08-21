vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

local function create_obsidian_figure()
	-- Get the current line (figure name)
	local line = vim.api.nvim_get_current_line():match("^%s*(.-)%s*$") -- trim whitespace

	if line == "" then
		vim.notify("Type figure name on current line first", vim.log.levels.WARN)
		return
	end

	-- Run the script and get the markdown syntax
	local result = vim.fn.system('obsidian-inkscape "' .. line .. '"')

	-- Check if command succeeded
	if vim.v.shell_error ~= 0 then
		vim.notify("Error creating figure: " .. result, vim.log.levels.ERROR)
		return
	end

	-- Clean the result (remove any trailing whitespace/newlines)
	local markdown_link = result:gsub("%s+$", "")

	-- Replace current line with markdown syntax
	local row = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { markdown_link })

	vim.notify("Figure created: " .. line, vim.log.levels.INFO)
end

-- Set up keybind for markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.keymap.set(
			{ "i", "n" },
			"<C-f>",
			create_obsidian_figure,
			{ buffer = true, desc = "Create Obsidian figure" }
		)
	end,
})
