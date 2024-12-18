---@diagnostic disable: undefined-global

local class_name = function()
  return vim.fn.expand '%:t:r'
end

local namespace = function()
  return vim.fn.expand('%:.:h'):gsub('app/', ''):gsub('%/', '\\')
end

local var_name = function(args)
  return sn(nil, {
    i(1, args[1][1]:gsub('^%u', string.lower):gsub('Interface', '') or ''),
  })
end

return {
  -- strict type
  s('strict', t 'declare(strict_types=1);'),

  -- dd
  s('dd', fmt([[dd({});{}]], { i(1), i(0) })),

  -- argument
  s(
    'arg',
    fmt([[{} ${}]], {
      i(1, 'Type'),
      d(2, var_name, { 1 }),
    })
  ),

  -- property
  s(
    'pro',
    fmt([[{} {} ${}{}]], {
      c(1, {
        t 'public',
        t 'protected',
        t 'private',
        t '',
      }),
      i(2, 'Type'),
      d(3, var_name, { 2 }),
      i(0),
    })
  ),

  -- function
  s(
    'func',
    fmt(
      [[
{} function {}({}): {}
{{
    {}
}}
]],
      {
        c(1, {
          t 'public',
          t 'protected',
          t 'private',
        }),
        i(2, ''),
        i(3, ''),
        i(4, 'void'),
        i(0),
      }
    )
  ),

  -- constructor
  s(
    '__con',
    fmt(
      [[
public function __construct({})
{{}}
]],
      {
        i(1, ''),
      }
    )
  ),

  -- class
  s(
    'class',
    fmt(
      [[
<?php

declare(strict_types=1);

namespace App\{};

{}

class {}
{{
    {}
}}
]],
      {
        f(namespace),
        i(1),
        f(class_name),
        i(0),
      }
    )
  ),

  -- foreach
  s(
    'foreach',
    fmta(
      [[
      foreach ($<exp> as $<val>) {
      <sta>
      }
      ]],
      {
        exp = i(1),
        val = i(2),
        sta = i(0),
      }
    )
  ),

  -- test
  s(
    'it',
    fmt(
      [[
      it('{}', function () {{
      {}
      }});
]],
      {
        i(1),
        i(0),
      }
    )
  ),
}
