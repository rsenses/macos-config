---@diagnostic disable: undefined-global
return {
  s({ trig = 'log' }, fmt([[console.log({})]], { i(1, '') })),
}
