local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Function to get current date in YYYY-MM-DD format
local function get_current_date()
  return os.date '%Y-%m-%d'
end


ls.add_snippets('markdown', {
  -- Basic expense row snippet (original)
  s('snip-expense', {
    t '| ',
    f(get_current_date),
    t ' | ',
    i(1, '0'),
    t ' | ',
    i(2, 'Category'),
    t ' | ',
    i(3, 'UPI'),
    t ' | ',
    i(4, 'Description'),
    t ' |',
  }),
})
