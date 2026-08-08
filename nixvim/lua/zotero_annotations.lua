-- Zotero Annotations by Highlight Color
-- Integrates with zotcite plugin, adds color-based annotation grouping

local M = {}

local zotero = require("zotcite.zotero")
local seek = require("zotcite.seek")
local zotcite_config = require("zotcite.config").get_config()

-- Color to heading mapping
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
  grouping = "highlight", -- "highlight" or "chronological"
  show_headings = true,
  show_yaml = true,
  show_info = true,
  images = true,     -- extract area/image annotations
  image_dir = nil,   -- nil = "<dir of current file>/images", else cache dir
  image_dpi = 300,   -- only used when rendering from the PDF ourselves
  base_attachment_path = nil, -- nil = read from Zotero prefs.js
  image_open_cmd = "xdg-open",
}

-- Zotero annotation type ids
local TYPE_HIGHLIGHT, TYPE_NOTE, TYPE_IMAGE, TYPE_INK, TYPE_UNDERLINE = 1, 2, 3, 4, 5

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

--- Image extraction -------------------------------------------------------

local function data_dir()
  local p = zotcite_config.zotero_sqlite_path
  if p and p ~= "" then return vim.fs.dirname(p) end
  return vim.fn.expand("~/Zotero")
end

-- Linked attachments ("attachments:foo.pdf") are relative to this
local base_attachment_path = nil
local function get_base_attachment_path()
  if base_attachment_path ~= nil then return base_attachment_path or nil end
  if M.config.base_attachment_path then
    base_attachment_path = M.config.base_attachment_path
    return base_attachment_path
  end
  base_attachment_path = false
  for _, f in ipairs(vim.fn.glob(vim.fn.expand("~/.zotero/zotero/*/prefs.js"), false, true)) do
    for _, line in ipairs(vim.fn.readfile(f)) do
      local v = line:match('"extensions%.zotero%.baseAttachmentPath",%s*"(.-)"')
      if v then
        base_attachment_path = v
        break
      end
    end
    if base_attachment_path then break end
  end
  return base_attachment_path or nil
end

-- Resolve the attachment's file on disk from itemAttachments.path
local function attachment_file(ann)
  local p = ann.attachPath
  if not p then return nil end

  local stored = p:match("^storage:(.+)$")
  if stored then
    return data_dir() .. "/storage/" .. (ann.attachKey or "") .. "/" .. stored
  end

  local linked = p:match("^attachments:(.+)$")
  if linked then
    local base = get_base_attachment_path()
    return base and (base .. "/" .. linked) or nil
  end

  return p -- absolute path
end

-- Zotero renders area annotations itself and caches them under <dataDir>/cache
local function cached_image(ann)
  local cache = data_dir() .. "/cache"
  local candidates = {
    cache .. "/library/" .. ann.annotKey .. ".png",
    cache .. "/groups/" .. tostring(ann.libraryID or "") .. "/" .. ann.annotKey .. ".png",
  }
  for _, c in ipairs(candidates) do
    if vim.uv.fs_stat(c) then return c end
  end
  local hits = vim.fn.glob(cache .. "/**/" .. ann.annotKey .. ".png", false, true)
  return hits[1]
end

local function page_height(pdf, page)
  local r = vim.system(
    { "pdfinfo", "-f", tostring(page), "-l", tostring(page), pdf },
    { text = true }
  ):wait(5000)
  if r.code ~= 0 or not r.stdout then return nil end
  local h = r.stdout:match("Page%s+%d+%s+size:%s+[%d%.]+%s+x%s+([%d%.]+)%s+pts")
    or r.stdout:match("Page%s+size:%s+[%d%.]+%s+x%s+([%d%.]+)%s+pts")
  return tonumber(h)
end

-- Fallback: crop the region straight out of the PDF (Zotero cache may be cold)
local function render_from_pdf(ann, out)
  if vim.fn.executable("pdftoppm") == 0 or vim.fn.executable("pdfinfo") == 0 then return nil end

  local pdf = attachment_file(ann)
  if not pdf or not vim.uv.fs_stat(pdf) or not pdf:lower():match("%.pdf$") then return nil end
  if not ann.rect then return nil end

  local page = (ann.pageIndex or 0) + 1
  local ph = page_height(pdf, page)
  if not ph then return nil end

  -- PDF points, origin bottom-left -> pixels at image_dpi, origin top-left
  local s = M.config.image_dpi / 72
  local x = math.max(0, math.floor(ann.rect[1] * s))
  local y = math.max(0, math.floor((ph - ann.rect[4]) * s))
  local w = math.ceil((ann.rect[3] - ann.rect[1]) * s)
  local h = math.ceil((ann.rect[4] - ann.rect[2]) * s)
  if w <= 0 or h <= 0 then return nil end

  local prefix = out:gsub("%.png$", "")
  local r = vim.system({
    "pdftoppm", "-png", "-singlefile",
    "-r", tostring(M.config.image_dpi),
    "-f", tostring(page), "-l", tostring(page),
    "-x", tostring(x), "-y", tostring(y), "-W", tostring(w), "-H", tostring(h),
    pdf, prefix,
  }, { text = true }):wait(30000)

  if r.code == 0 and vim.uv.fs_stat(out) then return out end
  return nil
end

local function image_dir()
  if M.config.image_dir then return vim.fn.expand(M.config.image_dir) end
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" and vim.uv.fs_stat(file) then
    return vim.fs.dirname(file) .. "/images"
  end
  return vim.fn.stdpath("cache") .. "/zotero_annotations/images"
end

-- Export one area annotation into dir, return its path (nil if impossible)
local function export_image(ann, dir, citekey)
  local name = string.format(
    "%s-p%s-%s.png",
    (citekey or "zotero"):gsub("[^%w%-_]", "_"),
    tostring(ann.pageLabel or ann.pageIndex or "?"):gsub("[^%w%-_]", "_"),
    ann.annotKey
  )
  local out = dir .. "/" .. name
  if vim.uv.fs_stat(out) then return out end

  vim.fn.mkdir(dir, "p")

  local cached = cached_image(ann)
  if cached and vim.uv.fs_copyfile(cached, out) then return out end

  return render_from_pdf(ann, out)
end

-- Get annotations WITH color from Zotero database (extends zotcite's version)
local function get_annotations_with_color(zotkey)
  if not zotcite_config.zotero_sqlite_path then return nil end

  -- Get tmpdir and db copy path (same logic as zotcite)
  local tmpdir = zotcite_config.tmpdir
  local zcopy = tmpdir .. "/copy_of_zotero.sqlite"

  -- Find itemID for this zotkey
  local query = string.format("SELECT itemID FROM items WHERE key = '%s'", zotkey)
  local result = vim.system({ "sqlite3", "-json", zcopy, query }, { text = true }):wait(3000)
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    return nil
  end

  local data = vim.json.decode(result.stdout)
  if not data or #data == 0 then return nil end
  local item_id = data[1].itemID

  -- Get annotations with color
  query = string.format([[
    SELECT
      itemAnnotations.type,
      itemAnnotations.text,
      itemAnnotations.comment,
      itemAnnotations.color,
      itemAnnotations.pageLabel,
      itemAnnotations.sortIndex,
      itemAnnotations.position,
      itemAnnotations.authorName,
      annItem.key AS annotKey,
      annItem.libraryID AS libraryID,
      attItem.key AS attachKey,
      itemAttachments.path AS attachPath
    FROM itemAttachments
    JOIN itemAnnotations ON itemAnnotations.parentItemID = itemAttachments.itemID
    JOIN items annItem ON annItem.itemID = itemAnnotations.itemID
    JOIN items attItem ON attItem.itemID = itemAttachments.itemID
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
      annotKey = row.annotKey ~= vim.NIL and row.annotKey or nil,
      libraryID = row.libraryID ~= vim.NIL and row.libraryID or nil,
      attachKey = row.attachKey ~= vim.NIL and row.attachKey or nil,
      attachPath = row.attachPath ~= vim.NIL and row.attachPath or nil,
    }

    if row.position and row.position ~= vim.NIL then
      local ok, pos = pcall(vim.json.decode, row.position)
      if ok and pos then
        ann.pageIndex = pos.pageIndex
        if pos.rects and pos.rects[1] then
          ann.posY = pos.rects[1][2]
          -- bounding box over all rects: what an area annotation covers
          local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
          for _, r in ipairs(pos.rects) do
            x1, y1 = math.min(x1, r[1]), math.min(y1, r[2])
            x2, y2 = math.max(x2, r[3]), math.max(y2, r[4])
          end
          ann.rect = { x1, y1, x2, y2 }
        elseif pos.paths then
          -- ink annotations store flat [x1,y1,x2,y2,...] path lists
          local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
          for _, path in ipairs(pos.paths) do
            for i = 1, #path - 1, 2 do
              x1, y1 = math.min(x1, path[i]), math.min(y1, path[i + 1])
              x2, y2 = math.max(x2, path[i]), math.max(y2, path[i + 1])
            end
          end
          if x1 < math.huge then
            ann.posY = y1
            ann.rect = { x1 - 5, y1 - 5, x2 + 5, y2 + 5 }
          end
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

  if ann.type == TYPE_IMAGE or ann.type == TYPE_INK then
    if ann.image then
      local link = vim.fn.fnamemodify(ann.image, ":.")
      local alt = "Area p. " .. (ann.pageLabel or "?")
      table.insert(output, string.format("![%s](%s)", alt, link))
      if not (ann.comment and #ann.comment > 0) then
        table.insert(output, "-" .. (meta ~= "" and meta or " *(area annotation)*"))
      end
    else
      table.insert(output, "- *(area annotation — image unavailable)*" .. meta)
    end
  end

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

-- Inline images need a graphics backend (image.nvim or snacks.image).
-- No-op when neither is installed; the markdown links still work.
local function render_inline_images(buf, win)
  local ok, snacks_doc = pcall(require, "snacks.image.doc")
  if ok and snacks_doc.attach then
    pcall(snacks_doc.attach, buf)
    return
  end

  local ok_img, img = pcall(require, "image")
  if not ok_img then return end

  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local link = line:match("!%[.-%]%((.-)%)")
    if link then
      local path = vim.fn.fnamemodify(link, ":p")
      if vim.uv.fs_stat(path) then
        local ok_from, image = pcall(img.from_file, path, {
          window = win,
          buffer = buf,
          with_virtual_padding = true,
          inline = true,
          y = i,
        })
        if ok_from and image then pcall(function() image:render() end) end
      end
    end
  end
end

local function display_annotations(annotations, item)
  local lines = {}
  local citekey = item.cite or item.key

  if M.config.images then
    local dir = image_dir()
    for _, ann in ipairs(annotations) do
      if ann.type == TYPE_IMAGE or ann.type == TYPE_INK then
        local ok, path = pcall(export_image, ann, dir, citekey)
        ann.image = ok and path or nil
      end
    end
  end

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
    -- Group by color
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
    -- Chronological by page
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

  -- Create floating window
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

  -- <CR> on an image line opens it in an external viewer
  vim.keymap.set("n", "<CR>", function()
    local link = vim.api.nvim_get_current_line():match("!%[.-%]%((.-)%)")
    if not link then return end
    vim.system({ M.config.image_open_cmd, vim.fn.fnamemodify(link, ":p") }, { detach = true })
  end, { buffer = buf, silent = true, desc = "Open annotation image" })

  vim.api.nvim_set_option_value("conceallevel", 2, { win = win })
  vim.api.nvim_set_option_value("concealcursor", "nc", { win = win })

  -- Render images in-place if an image backend is installed
  render_inline_images(buf, win)
end

-- Main entry: pick reference then show annotations
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

-- Get annotations for citation key under cursor
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

-- Commands
vim.api.nvim_create_user_command("ZoteroAnnotations", function(opts)
  M.pick_annotations(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ZoteroAnnotationsCursor", function()
  M.annotations_at_cursor()
end, {})

return M
