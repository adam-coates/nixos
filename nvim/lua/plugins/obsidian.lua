return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	dependencies = {
		"hrsh7th/nvim-cmp",
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{ "<leader>os", ":Obsidian search<cr>", desc = "Obsidian Search" },
	},
	opts = {
		legacy_commands = false,
		workspaces = {
			{
				name = "notes",
				path = "~/notes",
			},
		},
		open_notes_in = "vsplit",
		ui = { enable = false },
		completion = {
			min_chars = 2,
		},

		templates = {
			folder = "999-extra/Templates",
			date_format = "%d-%m-%Y",
			substitutions = {
				citation_title = function()
					vim.cmd("FindCitation")
				end,
			},
		},
		notes_subdir = "00 - Inbox", --all new notes go into the inbox
		attachments = {
			folder = "999-extra/images",
		},
		new_notes_location = "notes_subdir",
		link = {
			style = "markdown",
		},
		frontmatter = {
			enabled = false,
		},

		-- Optional, customize how note IDs are generated given an optional title.
		---@param title string|?
		---@return string
		note_id_func = function(title)
			-- Simply return the title exactly as is without any transformations
			if title then
				return title
			else
				-- If no title, generate a random ID
				local suffix = ""
				for _ = 1, 4 do
					suffix = suffix .. string.char(math.random(65, 90))
				end
				return "untitled_" .. suffix
			end
		end,
		footer = {
			enabled = true,
			separator = "",
			format = "{{backlinks}} backlinks",
		},
	},
}
