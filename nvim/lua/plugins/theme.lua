return {
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
}
