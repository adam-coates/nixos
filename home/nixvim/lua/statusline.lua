local M = {}

local api, fn, bo = vim.api, vim.fn, vim.bo
local get_opt = api.nvim_get_option_value

local icons = tools.ui.icons
local devicons = require("nvim-web-devicons")

local HL = {
	branch = { "DiagnosticOk", icons.branch },
	file = { "NonText", icons.node },
	fileinfo = { "Function", icons.document },
	nomodifiable = { "DiagnosticWarn", icons.bullet },
	modified = { "DiagnosticError", icons.bullet },
	readonly = { "DiagnosticWarn", icons.lock },
	error = { "DiagnosticError", icons.error },
	warn = { "DiagnosticWarn", icons.warning },
	visual = { "DiagnosticInfo", "‹› " },
}

local ICON = {}
for k, v in pairs(HL) do
	ICON[k] = tools.hl_str(v[1], v[2])
end

local ORDER = {
	"pad",
	"path",
	"venv",
	"mod",
	"ro",
	"sep",
	"diag",
	"fileinfo",
	"pad",
	"scrollbar",
	"pad",
}

local PAD = " "
local SEP = "%="

-- utilities -----------------------------------------
local function concat(parts)
	local out, i = {}, 1
	for _, k in ipairs(ORDER) do
		local v = parts[k]
		if v and v ~= "" then
			out[i] = v
			i = i + 1
		end
	end
	return table.concat(out, " ")
end

local function esc_str(str)
	return str:gsub("([%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
end

-- path and git info -----------------------------------------
local function path_widget(root, fname)
	local file_name = fn.fnamemodify(fname, ":t")

	local path, icon, hl
	icon, hl = devicons.get_icon(file_name, nil, { default = true })

	if fname == "" then
		file_name = "[No Name]"
	end
	path = tools.hl_str(hl, icon) .. file_name

	if bo.buftype == "help" then
		return ICON.file .. path
	end

	local dir_path = fn.fnamemodify(fname, ":h") .. "/"
	if dir_path == "./" then
		dir_path = ""
	end

	local remote = tools.get_git_remote_name(root)
	local branch = tools.get_git_branch(root)
	local repo_info = ""
	if remote and branch then
		dir_path = dir_path:gsub("^" .. esc_str(root) .. "/", "")
		repo_info = string.format("%s %s @ %s ", ICON.branch, remote, branch)
	end

	local win_w = api.nvim_win_get_width(0)
	local need = #repo_info + #dir_path + #path
	if win_w < need + 5 then
		dir_path = ""
	end
	if win_w < need - #dir_path then
		repo_info = ""
	end

	return repo_info .. ICON.file .. " " .. dir_path .. path .. " "
end

-- diagnostics ---------------------------------------------
local function diagnostics_widget()
	if not tools.diagnostics_available() then
		return ""
	end
	local diag_count = vim.diagnostic.count()
	local err, warn = string.format("%-3d", diag_count[1] or 0), string.format("%-3d", diag_count[2] or 0)

	return string.format(
		"%s %s  %s %s  ",
		ICON.error,
		tools.hl_str("DiagnosticError", err),
		ICON.warn,
		tools.hl_str("DiagnosticWarn", warn)
	)
end
-- markdown check ---------------------------------------------
local function is_markdown()
	return bo.filetype == "markdown" or bo.filetype == "asciidoc" or bo.filetype == "quarto"
end

-- file/selection info -------------------------------------
local function fileinfo_widget()
	local ft = get_opt("filetype", {})
	local lines = tools.group_number(api.nvim_buf_line_count(0), ",")
	local str = ICON.fileinfo .. " "

	-- For markdown files, show reading time
	if is_markdown() then
		local wc = fn.wordcount()
		local words = wc.visual_words or wc.words
		local reading_time = math.ceil(words / 200.0)

		if not wc.visual_words then
			return str
				.. string.format("%3s lines  %3s words  %s min", lines, tools.group_number(words, ","), reading_time)
		else
			local vlines = math.abs(fn.line(".") - fn.line("v")) + 1
			return str
				.. string.format(
					"%3s lines  %3s words  %3s chars  %s min",
					tools.group_number(vlines, ","),
					tools.group_number(wc.visual_words, ","),
					tools.group_number(wc.visual_chars, ","),
					reading_time
				)
		end
	end

	-- For non-programming modes (but not markdown)
	if not tools.nonprog_modes[ft] then
		return str .. string.format("%3s lines", lines)
	end

	local wc = fn.wordcount()
	if not wc.visual_words then
		return str .. string.format("%3s lines  %3s words", lines, tools.group_number(wc.words, ","))
	end

	local vlines = math.abs(fn.line(".") - fn.line("v")) + 1
	return str
		.. string.format(
			"%3s lines %3s words  %3s chars",
			tools.group_number(vlines, ","),
			tools.group_number(wc.visual_words, ","),
			tools.group_number(wc.visual_chars, ",")
		)
end
-- python venv ---------------------------------------------
local function venv_widget()
	if bo.filetype ~= "python" then
		return ""
	end
	local env = vim.env.VIRTUAL_ENV

	local str
	if env and env ~= "" then
		str = string.format("[.venv: %s]  ", fn.fnamemodify(env, ":t"))
		return tools.hl_str("Comment", str)
	end
	env = vim.env.CONDA_DEFAULT_ENV
	if env and env ~= "" then
		str = string.format("[conda: %s]  ", env)
		return tools.hl_str("Comment", str)
	end
	return tools.hl_str("Comment", "[no venv]")
end

-- scrollbar ---------------------------------------------
local function scrollbar_widget()
	local sbar_chars = {
		"▔", -- top
		"🮂",
		"🬂",
		"🮃",
		"▀",
		"▄",
		"▃",
		"🬭",
		"▂",
		"▁", -- bottom
	}

	local cur_line = api.nvim_win_get_cursor(0)[1]
	local lines = api.nvim_buf_line_count(0)

	local i = math.floor((cur_line - 1) / lines * #sbar_chars) + 1
	return string.rep(sbar_chars[i], 2)
end

-- render ---------------------------------------------
function M.render()
	local fname = api.nvim_buf_get_name(0)
	local root = (bo.buftype == "" and tools.get_path_root(fname)) or nil
	if bo.buftype ~= "" and bo.buftype ~= "help" then
		fname = bo.ft
	end

	local buf = api.nvim_win_get_buf(vim.g.statusline_winid)

	local parts = {
		pad = PAD,
		path = path_widget(root, fname),
		venv = venv_widget(),
		mod = get_opt("modifiable", { buf = buf }) and (get_opt("modified", { buf = buf }) and ICON.modified or " ")
			or ICON.nomodifiable,
		ro = get_opt("readonly", { buf = buf }) and ICON.readonly or "",
		sep = SEP,
		diag = diagnostics_widget(),
		fileinfo = fileinfo_widget(),
		scrollbar = scrollbar_widget(),
	}

	return concat(parts)
end

vim.o.statusline = "%!v:lua.require('ui.statusline').render()"

--vim.api.nvim_set_hl(0, "StatusLine", { bg = "#282828" })
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.cmd("redrawstatus")
	end,
})
return M
