local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Function to extract filename (without .md) as `id`, or fallback to current date-time if not in format
local function get_filename_id()
  local filename = vim.fn.expand '%:t:r' or '' -- Gets the current filename without the extension
  return filename:match '^(%d%d%d%d%d%d%d%d%d%d%d%d%d%d)$' or os.date '%Y%m%d%H%M%S' or 'YYYYMMDDHHMMSS'
end

local function get_current_datetime()
  return os.date '%Y-%m-%d %H:%M'
end

ls.add_snippets('markdown', {
  s('zetmd', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id), -- Automatically inserts the extracted ID
    t { '', 'title: ' },
    i(1, 'Title'),
    t { '', 'date: ' },
    f(get_current_datetime),
    t { '', 'type: ' },
    i(2, 'note'),
    t ' # note | concept | snippet | bug | journal | reference',
    t { '', 'status: ' },
    i(3, 'draft'),
    t ' # draft | stable | evergreen',
    t { '', 'tags: []' },
    t { '', 'links: []' },
    t { '', '---' },
    t { '', '# Log' },
    t { '', '- ' },
    f(get_current_datetime),
    t ' - Created note.',
    t { '', '', '# Notes', '', '' },
    i(0, 'Content'),
  }),
})
