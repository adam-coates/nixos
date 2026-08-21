return {
	-- Load all theme plugins but don't apply them
	-- This ensures all colorschemes are available for hot-reloading
	{
		"ribru17/bamboo.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
	},
	{
		"sainnhe/everforest",
		lazy = true,
		priority = 1000,
	},
	{
		"kepano/flexoki-neovim",
		lazy = true,
		priority = 1000,
	},
	{
		"sainnhe/gruvbox-material",
		enabled = true,
		priority = 1001,
		init = function()
			vim.g.gruvbox_material_foreground = "material"
			-- vim.g.gruvbox_material_transparent_background = 2
			vim.g.gruvbox_material_background = "original"
			vim.g.gruvbox_material_float_style = "blend"
			vim.g.gruvbox_material_statusline_style = "original"
			vim.g.gruvbox_material_cursor = "auto"
		end,
		config = function()
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},

	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"tahayvr/matteblack.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"loctvl842/monokai-pro.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"shaunsingh/nord.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		priority = 1000,
	},
	{
		"folke/tokyonight.nvim",
		lazy = true,
		priority = 1000,
	},
}
