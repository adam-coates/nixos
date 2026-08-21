return {
	"folke/zen-mode.nvim",
	event = "VeryLazy",
	dependencies = {
		"folke/twilight.nvim",
	},
	config = function()
		require("zen-mode").setup({
			window = {
				-- backdrop = 0.95,
				-- width = 150, -- width of the Zen window
				-- height = 1, -- height of the Zen window
				options = {
					signcolumn = "no", -- disable signcolumn
					number = false, -- disable number column
					relativenumber = false, -- disable relative numbers
				},
			},
			plugins = {
				twilight = { enabled = true },
				tmux = { enabled = true },
			},
		})
		require("twilight").setup({
			dimming = {
				alpha = 0.5,
			},
		})
	end,
}
