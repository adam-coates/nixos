return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "classic",
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		wk.add({
			{
				{ "<leader>c", group = "Code" },
				{ "<leader>e", group = "File Explorer" },
				{ "<leader>f", group = "Find Files" },
				{ "<leader>r", group = "Smart Rename/ RestartLSP" },
				{ "<leader>t", group = "Tab / Typst" },
				{ "z", group = "Folding" },
				{ "[", group = "Jump backwards" },
				{ "]", group = "Jump forwards" },
				{ "<leader>\\", group = "Toggle" },
				{ "g", group = "LSP" },
				{ "<leader>l", group = "[L]azy [G]it" },
				{ "<leader>m", group = "[M]ake [P]retty" },
				{ "<leader>o", group = "[O]bsidian" },
				{ "<leader>d", group = "[D]ebug" },
			},
		})
	end,
}
