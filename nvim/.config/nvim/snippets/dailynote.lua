local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Function to extract filename (without .md) as `id`, or fallback to current date-time if not in format
local function get_filename_id()
  local filename = vim.fn.expand '%:t:r' -- Gets the current filename without the extension
  return filename:match '^(%d%d%d%d%d%d%d%d)$' or os.date '%Y%m%d' or 'YYYYMMDD'
end

ls.add_snippets('markdown', {
  s('dailynote', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id), -- Calls the filename ID function when the snippet is expanded
    t { '', 'title: Daily Note' },
    t { '', 'type: daily' },
    t { '', 'date: ' },
    f(function()
      return os.date '%Y-%m-%d'
    end), -- Inserts the current date in YYYY-MM-DD format
    t { '', 'tags: [daily-notes]' },
    t { '', '---' },
    t { '', '' },
    t { '', '# Daily Notes - ' },
    f(function()
      return os.date '%Y-%m-%d'
    end), -- Inserts the current date as heading
    t { '', '' },
    t { '', '## Plan for today' },
    t { '', '' },
    t { '', '## Tasks & Progress' },
    t { '', '- [ ] ' },
    i(1, ''),
    t { '', '' },
    t { '', '## Plan for next day' },
    i(0, ''),
  }),
})
