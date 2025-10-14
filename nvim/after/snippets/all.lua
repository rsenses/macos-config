---@diagnostic disable: undefined-global

return {
  -- year
  s('year', { extras.partial(os.date, '%Y') }),

  -- date
  s('date', { extras.partial(os.date, '%Y-%m-%d') }),

  -- datetime
  s('datetime', { extras.partial(os.date, '%Y-%m-%d %H:%M') }),
}
