local M = {}

local zotero = require("zotcite.zotero")
local seek = require("zotcite.seek")
local zotcite_config = require("zotcite.config").get_config()

M.color_headings = {
  ["#ffd400"] = "## Key Points",
  ["#ff6666"] = "## Background",
  ["#5fb236"] = "## Hypothesis / Positive",
  ["#2ea8e5"] = "## Methods / Process",
  ["#a28ae5"] = "## Results / Data",
  ["#e56eee"] = "## Conclusions / Questions",
  ["#f19837"] = "## Implications / ToDo",
  ["#aaaaaa"] = "## Further Reading / Misc",
}

M.config = {
  grouping = "highlight",
  show_headings = true,
  show_yaml = true,
  show_info = true,
}

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  if opts.color_headings then
    local normalized = {}
    for color, heading in pairs(opts.color_headings) do
      normalized[string.lower(color)] = heading
    end
    M.color_headings = normalized
  end
end

local function get_annotations_with_color(zotkey)
  if not zotcite_config.zotero_sqlite_path then return nil end

  local tmpdir = zotcite_config.tmpdir
  local zcopy = tmpdir .. "/copy_of_zotero.sqlite"

  local query = string.format("SELECT itemID FROM items WHERE key = '%s'", zotkey)
  local result = vim.system({ "sqlite3", "-json", zcopy, query }, { text = true }):wait(3000)
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    return nil
  end

  local data = vim.json.decode(result.stdout)
  if not data or #data == 0 then return nil end
  local item_id = data[1].itemID

  query = string.format([[
    SELECT
      itemAnnotations.type,
      itemAnnotations.text,
      itemAnnotations.comment,
      itemAnnotations.color,
      itemAnnotations.pageLabel,
      itemAnnotations.sortIndex,
      itemAnnotations.position,
      itemAnnotations.authorName
    FROM itemAttachments
    JOIN itemAnnotations ON itemAnnotations.parentItemID = itemAttachments.itemID
    WHERE itemAttachments.parentItemID = %d
    ORDER BY itemAnnotations.sortIndex
  ]], item_id)

  result = vim.system({ "sqlite3", "-json", zcopy, query }, { text = true }):wait(3000)
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    return {}
  end

  data = vim.json.decode(result.stdout)
  local annotations = {}
  for _, row in ipairs(data or {}) do
    local ann = {
      type = row.type,
      text = row.text ~= vim.NIL and row.text or nil,
      comment = row.comment ~= vim.NIL and row.comment or nil,
      color = row.color ~= vim.NIL and string.lower(row.color) or nil,
      pageLabel = row.pageLabel ~= vim.NIL and row.pageLabel or nil,
      sortIndex = row.sortIndex,
      authorName = row.authorName ~= vim.NIL and row.authorName or nil,
    }

    if row.position and row.position ~= vim.NIL then
      local ok, pos = pcall(vim.json.decode, row.position)
      if ok and pos then
        ann.pageIndex = pos.pageIndex
        if pos.rects and pos.rects[1] then
          ann.posY = pos.rects[1][2]
        end
      end
    end

    table.insert(annotations, ann)
  end

  table.sort(annotations, function(a, b)
    local pa = a.pageIndex or -1
    local pb = b.pageIndex or -1
    if pa ~= pb then return pa < pb end
    return (a.posY or 0) > (b.posY or 0)
  end)

  return annotations
end

local function generate_yaml(item)
  local lines = { "---" }

  if item.cite then
    table.insert(lines, "citekey: " .. item.cite)
  end

  if item.title and item.author and #item.author > 0 then
    local author_str = item.author[1][1]
    if #item.author > 1 then
      author_str = author_str .. " et al."
    end
    table.insert(lines, "aliases:")
    table.insert(lines, string.format('- "%s (%s) %s"', author_str, item.year or "", item.title))
  end

  if item.title then
    table.insert(lines, 'title: "' .. item.title .. '"')
  end

  if item.author and #item.author > 0 then
    table.insert(lines, "authors:")
    for _, a in ipairs(item.author) do
      table.insert(lines, "- " .. (a[2] or "") .. " " .. (a[1] or ""))
    end
  end

  if item.year then
    table.insert(lines, "year: " .. item.year)
  end

  table.insert(lines, "---")
  table.insert(lines, "")
  return lines
end

local function generate_info(item)
  local lines = {}
  local zotero_link = "zotero://select/library/items/" .. item.key

  table.insert(lines, "> [!info]- Info [**Zotero**](" .. zotero_link .. ")")
  table.insert(lines, ">")

  if item.author and #item.author > 0 then
    local links = {}
    for _, a in ipairs(item.author) do
      local name = (a[2] or "") .. " " .. (a[1] or "")
      table.insert(links, "[[" .. name .. "]]")
    end
    table.insert(lines, "> **Authors**:: " .. table.concat(links, ", "))
  end

  if item.abstract then
    table.insert(lines, "")
    table.insert(lines, "> [!abstract]-")
    table.insert(lines, "> " .. item.abstract:gsub("\n", "\n> "))
  end

  table.insert(lines, "")
  return lines
end

local function format_annotation(ann, citekey)
  local output = {}
  local meta_parts = {}
  if citekey then table.insert(meta_parts, "@" .. citekey) end
  if ann.pageLabel then table.insert(meta_parts, "p. " .. ann.pageLabel) end
  local meta = #meta_parts > 0 and (" [" .. table.concat(meta_parts, ", ") .. "]") or ""

  if ann.comment and #ann.comment > 0 then
    for i, line in ipairs(vim.split(ann.comment, "\n")) do
      if i == 1 then
        table.insert(output, "- *" .. line .. "*" .. meta)
      else
        table.insert(output, "  *" .. line .. "*")
      end
    end
  end

  if ann.text and #ann.text > 0 then
    for i, line in ipairs(vim.split(ann.text, "\n")) do
      if i == 1 then
        table.insert(output, "> " .. line .. meta)
      else
        table.insert(output, "> " .. line)
      end
    end
  end

  return output
end

local function display_annotations(annotations, item)
  local lines = {}
  local citekey = item.cite or item.key

  if M.config.show_yaml then
    vim.list_extend(lines, generate_yaml(item))
  end

  if M.config.show_info then
    vim.list_extend(lines, generate_info(item))
  end

  table.insert(lines, "## Annotations: " .. (item.title or citekey))
  table.insert(lines, "")

  if #annotations == 0 then
    table.insert(lines, "> No annotations found.")
  elseif M.config.grouping == "highlight" then
    local color_order = {
      "#ffd400", "#ff6666", "#5fb236", "#2ea8e5",
      "#a28ae5", "#e56eee", "#f19837", "#aaaaaa",
    }
    local by_color = {}
    local other = {}

    for _, ann in ipairs(annotations) do
      local c = ann.color
      if c and M.color_headings[c] then
        by_color[c] = by_color[c] or {}
        table.insert(by_color[c], ann)
      else
        table.insert(other, ann)
      end
    end

    local first = true
    for _, color in ipairs(color_order) do
      if by_color[color] and #by_color[color] > 0 then
        if not first then
          table.insert(lines, "---")
          table.insert(lines, "")
        end
        if M.config.show_headings then
          table.insert(lines, M.color_headings[color])
          table.insert(lines, "")
        end
        for _, ann in ipairs(by_color[color]) do
          vim.list_extend(lines, format_annotation(ann, citekey))
          table.insert(lines, "")
        end
        first = false
      end
    end

    if #other > 0 then
      if not first then
        table.insert(lines, "---")
        table.insert(lines, "")
      end
      if M.config.show_headings then
        table.insert(lines, "## Other")
        table.insert(lines, "")
      end
      for _, ann in ipairs(other) do
        vim.list_extend(lines, format_annotation(ann, citekey))
        table.insert(lines, "")
      end
    end

  else
    local current_page = nil
    for _, ann in ipairs(annotations) do
      if ann.pageLabel ~= current_page then
        if current_page then
          table.insert(lines, "---")
          table.insert(lines, "")
        end
        table.insert(lines, "### Page " .. (ann.pageLabel or "?"))
        table.insert(lines, "")
        current_page = ann.pageLabel
      end
      vim.list_extend(lines, format_annotation(ann, citekey))
      table.insert(lines, "")
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local width = math.floor(vim.o.columns * 0.75)
  local height = math.floor(vim.o.lines * 0.75)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Annotations: " .. citekey .. " ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })

  vim.api.nvim_set_option_value("conceallevel", 2, { win = win })
  vim.api.nvim_set_option_value("concealcursor", "nc", { win = win })
end

function M.pick_annotations(pattern)
  pattern = pattern or ""
  seek.refs(pattern, function(selection)
    if not selection then return end
    local item = selection.value
    local annotations = get_annotations_with_color(item.key)
    if not annotations then
      vim.notify("Could not fetch annotations", vim.log.levels.WARN)
      return
    end
    display_annotations(annotations, item)
  end)
end

function M.annotations_at_cursor()
  local key = require("zotcite.get").citation_key()
  if not key or key == "" then
    vim.notify("No citation key under cursor", vim.log.levels.INFO)
    return
  end

  local ref_data = zotero.get_ref_data(key)
  if not ref_data then
    vim.notify("Citation key not found: " .. key, vim.log.levels.WARN)
    return
  end

  local annotations = get_annotations_with_color(ref_data.zotkey)
  if not annotations then
    vim.notify("Could not fetch annotations", vim.log.levels.WARN)
    return
  end

  local item = {
    key = ref_data.zotkey,
    cite = ref_data.citekey,
    title = ref_data.title,
    year = ref_data.year,
    author = ref_data.author,
    abstract = ref_data.abstractNote,
  }
  display_annotations(annotations, item)
end

vim.api.nvim_create_user_command("ZoteroAnnotations", function(opts)
  M.pick_annotations(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ZoteroAnnotationsCursor", function()
  M.annotations_at_cursor()
end, {})

return M
