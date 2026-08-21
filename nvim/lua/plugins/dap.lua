return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"mfussenegger/nvim-dap-python",
			"theHamsta/nvim-dap-virtual-text",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local dap_python = require("dap-python")

			require("dapui").setup({})
			require("nvim-dap-virtual-text").setup({
				commented = true, -- Show virtual text alongside comment
			})

			dap_python.setup("python3")

			vim.fn.sign_define("DapBreakpoint", {
				text = "",
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})

			vim.fn.sign_define("DapBreakpointRejected", {
				text = "", -- or "❌"
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})

			vim.fn.sign_define("DapStopped", {
				text = "", -- or "→"
				texthl = "DiagnosticSignWarn",
				linehl = "Visual",
				numhl = "DiagnosticSignWarn",
			})

			-- Automatically open/close DAP UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

			local opts = { noremap = true, silent = true }

			-- Toggle breakpoint
			vim.keymap.set("n", "<leader>db", function()
				require("dap").toggle_breakpoint()
			end, vim.tbl_extend("force", opts, { desc = "Toggle Breakpoint" }))

			-- Continue / Start
			vim.keymap.set("n", "<leader>dc", function()
				require("dap").continue()
			end, vim.tbl_extend("force", opts, { desc = "Start/Continue Debugging" }))

			-- Step Over
			vim.keymap.set("n", "<leader>do", function()
				require("dap").step_over()
			end, vim.tbl_extend("force", opts, { desc = "Step Over" }))

			-- Step Into
			vim.keymap.set("n", "<leader>di", function()
				require("dap").step_into()
			end, vim.tbl_extend("force", opts, { desc = "Step Into" }))

			-- Step Out
			vim.keymap.set("n", "<leader>dO", function()
				require("dap").step_out()
			end, vim.tbl_extend("force", opts, { desc = "Step Out" }))

			-- Terminate Debugging
			vim.keymap.set("n", "<leader>dq", function()
				require("dap").terminate()
			end, vim.tbl_extend("force", opts, { desc = "Quit Debugging" }))

			-- Toggle DAP UI
			vim.keymap.set("n", "<leader>du", function()
				require("dapui").toggle()
			end, vim.tbl_extend("force", opts, { desc = "Toggle DAP UI" }))
		end,
	},
}
