return {
	"adam-coates/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	build = "cd app && yarn install",
	init = function()
		vim.g.mkdp_filetypes = { "markdown" }
	end,
	ft = { "markdown" },
	-- "iamcco/markdown-preview.nvim",
	-- version = "0.0.10",
	-- cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
	-- event = "VeryLazy",
	-- ft = { "markdown", "quarto" },
	-- config = function()
	-- 	-- Can't get lazy build to work ¯\_(ツ)_/¯
	-- 	-- This first time loading the plugin, there will be a significant delay becuase the function is synchronous, but after that it shouldn't be noticeable
	-- 	-- TODO: Either figure out how to get lazy build to work, or figure out how to make this asynchronous
	-- 	local install_path = vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim/app"
	-- 	local node_modules = install_path .. "/node_modules"
	-- 	if vim.fn.empty(vim.fn.glob(node_modules)) > 0 then
	-- 		vim.cmd("!cd " .. install_path .. " && npm install && git restore .")
	-- 	end
	--
	-- 	-- Options
	-- 	vim.g.mkdp_auto_close = 0
	-- 	vim.g.mkdp_page_title = "${name} - Preview"
	-- 	vim.g.mkdp_echo_preview_url = 1
	-- end,
}
