local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Function to extract filename (without .md) as `id`
local function get_filename_id()
  local filename = vim.fn.expand '%:t:r' -- Gets the current filename without the extension
  return filename:match '^(%d%d%d%d%d%d%d%d%d%d%d%d%d%d)$' or os.date '%Y%m%d%H%M%S' or 'YYYYMMDDHHMMSS'
end

ls.add_snippets('markdown', {
  s('weeklynote', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id), -- Calls the filename ID function when the snippet is expanded
    t { '', 'title: Weekly Note' },
    t { '', 'type: weekly' },
    t { '', 'date: ' },
    f(function()
      return os.date '%Y-%m-%d'
    end), -- Inserts the current date in YYYY-MM-DD format
    t { '', 'tags: [weekly-notes]' },
    t { '', '---' },
    t { '', '' },
    t { '', '# Weekly Notes - ' },
    f(function()
      return os.date '%Y-%m-%d'
    end), -- Inserts the current date as heading
    t { '', '' },
    t { '', '## Plan for this week' },
    t { '', '- [ ] ' },
    i(1, ''), -- This is now the insert node for modifying the task text
  }),
})
