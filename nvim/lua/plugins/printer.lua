return {
	"adam-coates/printer.nvim",
	config = function()
		require("printer").setup({
			python_cmd = "uv run", -- or "python3"
			printer_vendor_id = "0x04B8", -- Your printer's vendor ID
			printer_product_id = "0x0E39", -- Your printer's product ID
			line_width = 48, -- Characters per line
		})

		-- Commands
		vim.api.nvim_create_user_command("PrintBuffer", require("printer").print_buffer, {})
		vim.api.nvim_create_user_command("PrintLine", require("printer").print_current_line, {})
		vim.api.nvim_create_user_command("PrintLive", require("printer").toggle_live_mode, {})

		-- Keybindings
		vim.keymap.set("n", "<leader>pb", require("printer").print_buffer, { desc = "Print buffer" })
		vim.keymap.set("n", "<leader>pl", require("printer").print_current_line, { desc = "Print current line" })
		vim.keymap.set("v", "<leader>pp", require("printer").print_selection, { desc = "Print selection" })
		vim.keymap.set("n", "<leader>pL", require("printer").toggle_live_mode, { desc = "Toggle live printing" })
	end,
}
