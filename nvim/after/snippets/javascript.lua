---@diagnostic disable: undefined-global

return {
  -- strict type
  s('st', t 'declare(strict_types=1);'),

  -- console log
  s(
    'log',
    fmta([[console.log(<content>)]], {
      content = i(1),
    })
  ),
}
