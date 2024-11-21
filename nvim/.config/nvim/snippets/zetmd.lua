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

ls.add_snippets('markdown', {
  s('zetmd', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id), -- Automatically inserts the extracted ID
    t { '', 'title: ' },
    i(1, 'Title'),
    t { '', 'date: ' },
    f(function()
      return os.date '%Y-%m-%d %H:%M'
    end), -- Inserts the current date in YYYY-MM-DD format
    t { '', 'tags: [' },
    i(2, ''), -- Empty tags for customization
    t ']',
    t { '', 'links: [' },
    i(3, ''), -- Empty links field for customization
    t ']',
    t { '', '---' },
    t { '', '' },
    t { '', '- [./]() - ' },
    i(4, 'Add link context: why notes are connected'),
    t { '', '- [./]() - ' },
    i(5, 'Add link context: why notes are connected'),
    t { '', '' },
    t { '', '---' },
    t { '', '' },
    t { '', '# ' },
    i(6, 'ContentHeading'),
    t { '', '' },
    t { '', '' },
    i(0, 'Content'),
  }),
})
