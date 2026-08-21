return {
	"jalvesaq/zotcite",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("zotcite").setup({
			zotero_sqlite_path = "/home/adam/Zotero/zotero.sqlite",
			attach_dir = "/home/adam/Nextcloud/zotero",
			open_in_zotero = true,
			key_type = "better-bibtex",
		})

		require("zotero_annotations").setup()
	end,
}
