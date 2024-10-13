-- ~/.config/nvim/snippets/markdown.lua
local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets('markdown', {
  s('zetmd', {
    t '---',
    t { '', 'title: ' },
    i(1, 'Title'),
    t { '', 'date: ' },
    i(2, 'Date'),
    t { '', 'tags: [' },
    i(3, 'Tags'),
    t ']',
    t { '', 'links: [' },
    i(4, 'Links'),
    t ']',
    t { '', '---' },
    t { '', '' },
    t { '', '# ' },
    i(5, 'Title'),
    t { '', '' },
    t { '', '' },
    i(0, 'Content'),
  }),
})
