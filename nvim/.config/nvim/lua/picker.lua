-- Floating line picker: j/k move, 1-9 pick directly, <CR> confirm, q/<Esc> cancel.

local M = {}

local defaults = {
  border = 'rounded',
  min_width = 8,
  padding = 2,
}

local function trim(value)
  return value:gsub('^%s*(.-)%s*$', '%1')
end

local function clamp(value, min, max)
  return math.max(min, math.min(value, max))
end

local function compute_width(lines, title, opts)
  local w = opts.min_width
  for _, line in ipairs(lines) do
    w = math.max(w, vim.fn.strdisplaywidth(line) + opts.padding)
  end
  if title then
    local inner = trim(title)
    w = math.max(w, vim.fn.strdisplaywidth(inner) + 4)
  end
  return clamp(w, opts.min_width, math.max(opts.min_width, vim.o.columns - 4))
end

local function resolve_text(text)
  if type(text) == 'function' then
    return text()
  end
  return text
end

local function run_item(item)
  if item.action then
    item.action()
    return
  end
  if item.text ~= nil then
    vim.api.nvim_put({ resolve_text(item.text) }, 'c', true, true)
  end
end

---@class PickerItem
---@field label string
---@field action? fun()
---@field text? string|fun(): string

--- Open a centered float; each item runs `action` or inserts `text` after close.
---@param opts { title?: string, items: PickerItem[], on_cancel?: fun(), format_item?: fun(item: PickerItem, idx: integer): string, border?: string, min_width?: integer, padding?: integer }
function M.open(opts)
  opts = vim.tbl_extend('force', defaults, opts or {})
  local items = opts.items
  assert(items and #items > 0, 'picker.open: opts.items must be a non-empty list')

  local lines = {}
  for idx, item in ipairs(items) do
    local label = opts.format_item and opts.format_item(item, idx) or item.label
    lines[idx] = string.format('%d. %s', idx, label)
  end

  local width = compute_width(lines, opts.title, opts)
  local max_height = math.max(1, vim.o.lines - 6)
  local height = math.min(#lines, max_height)
  local title = opts.title or ' Pick '

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'

  local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = opts.border,
    title = title,
    title_pos = 'center',
  })
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  local function cleanup()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function confirm()
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    cleanup()
    local item = items[idx]
    if item then
      run_item(item)
    end
  end

  local function cancel()
    cleanup()
    if opts.on_cancel then
      opts.on_cancel()
    end
  end

  vim.keymap.set('n', '<CR>', confirm, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set('n', '<Esc>', cancel, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set('n', 'q', cancel, { buffer = buf, silent = true, nowait = true })

  for idx = 1, math.min(#items, 9) do
    vim.keymap.set('n', tostring(idx), function()
      cleanup()
      run_item(items[idx])
    end, { buffer = buf, silent = true, nowait = true })
  end
end

--- Build items that insert `text` (string or fun(): string) at the cursor with nvim_put.
---@param opts { title?: string, rows: { label: string, text: string|(fun(): string) }[], on_cancel?: fun() }
function M.open_insert_rows(opts)
  local items = {}
  for _, row in ipairs(opts.rows) do
    items[#items + 1] = {
      label = row.label,
      action = function()
        local t = row.text
        if type(t) == 'function' then
          t = t()
        end
        vim.api.nvim_put({ t }, 'c', true, true)
      end,
    }
  end
  M.open({
    title = opts.title,
    items = items,
    on_cancel = opts.on_cancel,
  })
end

return M
