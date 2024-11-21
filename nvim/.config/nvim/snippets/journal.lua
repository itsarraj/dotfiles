local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Robust filename ID extraction with fallback
local function get_filename_id()
  local filename = vim.fn.expand '%:t:r' or ''
  return filename:match '^(%d+)$' or os.date '%Y%m%d%H%M%S'
end

local function get_filename_date()
  local filename = vim.fn.expand '%:t:r' or ''

  -- Extract the date part from the filename (e.g., YYYYMMDD or YYYYMMDDHHMMSS)
  local year, month, day, hour, minute, second = filename:match '^(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)$'

  -- Fallback to current date and time if filename doesn't match
  if not year or not month or not day then
    year, month, day = os.date '%Y', os.date '%m', os.date '%d'
    hour, minute, second = os.date '%H', os.date '%M', os.date '%S'
  end

  -- Return in YYYY-MM-DD format (ignoring HHMMSS if it's not present)
  return string.format('%s-%s-%s', year, month, day)
end

-- dailynote.lua

-- Generate daily schedule with sleep time from 22:00 to 06:00
-- local function generate_daily_schedule()
--   local lines = {}
--
--   -- Sleep time from 22:00 to 06:00
--   for hour = 22, 23 do
--     table.insert(lines, string.format('%02d:00 - Sleep [ ]', hour))
--   end
--   for hour = 0, 5 do
--     table.insert(lines, string.format('%02d:00 - Sleep [ ]', hour))
--   end
--
--   -- From 06:00 onward, hourly intervals for tasks
--   for hour = 6, 21 do
--     table.insert(lines, string.format('%02d:00 - [ ]', hour))
--     table.insert(lines, '') -- Blank line between hours for better readability
--   end
--
--   -- Sleep time continuation from 22:00
--   for hour = 22, 23 do
--     table.insert(lines, string.format('%02d:00 - Sleep [ ]', hour))
--   end
--
--   return lines
-- end

ls.add_snippets('markdown', {
  s('dailynote', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id),
    t { '', 'title: Daily Note' },
    t { '', 'type: daily' },
    t { '', 'date: ' },
    f(get_filename_date),
    t { '', 'tags: [daily-notes]' },
    t { '', '---' },
    t { '', '' },

    t { '## Goals and Plans for today', '' },
    i(1),
    t { '', '' },
    t { '## Tasks & Progress', '' },
    i(2),
    t { '', '' },
    t { '## Goals and Plans for next day', '' },
    i(3),
    t { '', '' },
    t { '## Distribution of Task', '' },
    i(0),
  }),
})

-- weeklynote.lua

local function generate_weekly_plan()
  local year, month, day = get_filename_date():match '^(%d%d%d%d)%-(%d%d)%-(%d%d)$'
  local date = os.time { year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0 }

  -- Find the previous Sunday (or the same day if it's Sunday)
  local weekday = tonumber(os.date('%w', date)) -- Get the weekday (0=Sunday, 1=Monday, ..., 6=Saturday)
  local sunday_date = date - (weekday * 24 * 3600) -- Subtract the days to get to Sunday

  local days = {}
  -- Generate dates from Sunday to Saturday
  for day_of_week = 0, 6 do
    -- Calculate the exact date for each day of the week (Sunday to Saturday)
    local day_in_week = os.date('%Y-%m-%d', sunday_date + (day_of_week * 24 * 3600))
    table.insert(days, '- ' .. day_in_week .. '')
  end
  return days
end

ls.add_snippets('markdown', {
  s('weeklynote', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id),
    t { '', 'title: Weekly Note' },
    t { '', 'type: weekly' },
    t { '', 'date: ' },
    f(get_filename_date),
    t { '', 'tags: [weekly-notes]' },
    t { '', '---' },
    t { '', '' },
    t { '', '# Weekly Notes - ' },
    f(get_filename_date),
    t { '', '' },
    t { '', '## Goals and Plans for this week' },
    t { '', '' },
    i(1),
    t { '', '## Tasks & Progress' },
    t { '', '' },
    i(2),
    t { '', '## Goals and Plans for next week' },
    t { '', '' },
    i(0),
    t { '', '## Distribution of Task' },
    t { '', '' },
    t(generate_weekly_plan()),
  }),
})

-- monthlynote.lua -- abandonded

local function get_filename_year_month()
  local filename = vim.fn.expand '%:t:r' or ''
  -- Capture first six digits for year and month
  local year, month = filename:match '^(%d%d%d%d)(%d%d)'
  return year or os.date '%Y', month or os.date '%m'
end

local function generate_monthly_plan()
  local year, month = get_filename_year_month()
  local year_num, month_num = tonumber(year), tonumber(month)

  local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

  local function is_leap_year(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
  end

  -- Handle leap year for February
  if month_num == 2 and is_leap_year(year_num) then
    days_in_month[2] = 29
  end

  local lines = {}
  for day = 1, days_in_month[month_num] do
    local day_str = string.format('%02d', day)
    table.insert(lines, '- ' .. year .. '-' .. month .. '-' .. day_str .. ' - [ ] ')
  end
  return lines
end

ls.add_snippets('markdown', {
  s('monthlynote', {
    t '---',
    t { '', 'id: ' },
    f(get_filename_id), -- Generate a unique ID based on filename or timestamp
    t { '', 'title: Monthly Note' },
    t { '', 'type: monthly' },
    t { '', 'date: ' },
    f(get_filename_date),
    t { '', 'tags: [monthly-notes]' },
    t { '', '---' },
    t { '', '' },
    t { '', '# Monthly Notes - ' },
    f(function()
      local year, month = get_filename_year_month()
      return year .. '-' .. month
    end),
    t { '', '' },
    -- Goal for the Month section
    t { '', '## Goal for This Month' },
    t { '', '- ' },
    i(1), -- Input placeholder for goal
    t { '', '' },
    -- Tasks & Progress section
    t { '', '## Tasks & Progress' },
    t { '', '- [ ] ' },
    i(2), -- Input placeholder for tasks
    t { '', '' },
    t { '', '---' },
    -- Plans to Execute section with auto-generated dates
    t { '', '## Plans to Execute' },
    t { '', '' },
    t(generate_monthly_plan()),
    t { '', '---' },
    -- Monthly Review & Next Steps section
    t { '', '## Monthly Review & Next Steps' },
    t { '', '### Review:' },
    t { '', '- ' },
    i(6), -- Input placeholder for review
    t { '', '### Next Steps:' },
    t { '', '- ' },
    i(7), -- Input placeholder for next steps
    t { '', '' },
  }),
})

-- yearlynote.lua
local function get_filename_year()
  local filename = vim.fn.expand '%:t:r' or ''
  local year = filename:sub(1, 4)
  return tostring(tonumber(year) or os.date '%Y')
end

local function generate_monthly_plan_for_yearly()
  local year = get_filename_year()
  local months = {
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  }
  local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

  local function is_leap_year(y)
    y = tonumber(y)
    return y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)
  end

  -- Adjust for leap years
  if is_leap_year(year) then
    days_in_month[2] = 29
  end

  local lines = {}
  for month_idx, month_name in ipairs(months) do
    table.insert(lines, '---')
    table.insert(lines, '## ' .. month_name .. ' ' .. year)

    -- Monthly sections
    for day = 1, days_in_month[month_idx] do
      table.insert(lines, '- ' .. year .. '-' .. string.format('%02d-%02d', month_idx, day) .. ' - [ ] ')
    end
    table.insert(lines, '')
  end
  return lines
end

ls.add_snippets('markdown', {
  s('yearlynote', {
    t { '---', 'id: ' },
    f(get_filename_year),
    t { '', 'title: Yearly Note', 'type: yearly', 'date: ' },
    f(get_filename_year),
    t { '', 'tags: [yearly-notes]', '---', '' },

    t { '## Goals and Plans', '' },
    i(1),
    t { '', '' },

    t { '## Tasks & Progress', '' },
    i(0),
    t { '', '' },

    t { '', '' },
    t(generate_monthly_plan_for_yearly()),
    t { '', '' },
  }),
})
