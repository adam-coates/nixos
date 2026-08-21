vim.g.mapleader = " "
vim.g.maplocalleader = ","

local keymap = vim.keymap -- for conciseness

keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace current word" })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- scroll in middle
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

keymap.set("x", "p", '"_dP')

-- move selected lines up or down
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Better movement
vim.keymap.set("n", "j", "gj", { noremap = true, silent = true })
vim.keymap.set("n", "k", "gk", { noremap = true, silent = true })
vim.keymap.set("v", "j", "gj", { noremap = true, silent = true })
vim.keymap.set("v", "k", "gk", { noremap = true, silent = true })

-- Obsidian note creation
keymap.set("n", "<leader>on", function()
	if vim.fn.bufname("%") == "" and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
		local title = vim.fn.input("Enter note title: ")
		if title == "" then
			print("Title cannot be empty!")
			return
		end

		local dir = vim.fn.expand("~/notes/00 - Inbox/")
		local filename = dir .. title .. ".md"

		vim.fn.mkdir(dir, "p")

		vim.cmd("edit " .. filename)
		vim.cmd("write")
	end

	local original_cwd = vim.fn.getcwd()
	vim.cmd("cd ~/notes")
	vim.cmd(":Obsidian template note")
	vim.cmd("cd " .. original_cwd)
end, { desc = "Create Obsidian note with template" })
