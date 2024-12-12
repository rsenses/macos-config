---@diagnostic disable: undefined-global

local class_name = function()
  return vim.fn.expand '%:t:r'
end

local var_name = function(args)
  return sn(nil, {
    i(1, args[1][1]:gsub('^%u', string.lower):gsub('Interface', '') or ''),
  })
end

return {
  -- strict type
  s('st', t 'declare(strict_types=1);'),

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
    fmt([[{} {}{} ${},]], {
      c(1, {
        t 'public',
        t 'protected',
        t 'private',
      }),
      c(2, {
        t 'readonly ',
        t '',
      }),
      i(3, 'Type'),
      d(4, var_name, { 3 }),
    })
  ),

  -- var
  s(
    'var',
    fmt(
      [[
/**
 * @var {}
 */
{} {} ${};
]],
      {
        i(1, 'type'),
        c(2, {
          t 'public',
          t 'protected',
          t 'private',
        }),
        i(3, 'Type'),
        i(4, 'var'),
      }
    )
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
    'cons',
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

class {}
{{
    {}
}}
]],
      {
        i(1, ''),
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
