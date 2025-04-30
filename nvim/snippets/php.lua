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

--- Busca la primera variable PHP ($nombre) en la línea siguiente al cursor.
-- @return string La variable encontrada (ej: "$variable"), o "$x" si no se encuentra
--                o si no hay línea siguiente.
local function next_var()
  -- Obtener la ventana, buffer y posición del cursor actuales
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(win) -- {fila, col} (fila base 1, col base 0)
  local current_line_num = cursor[1]

  -- Calcular el número de la línea siguiente
  local next_line_num = current_line_num + 1

  -- Verificar si la línea siguiente existe en el buffer
  local line_count = vim.api.nvim_buf_line_count(buf)
  if next_line_num > line_count then
    -- No hay línea siguiente, devolvemos el valor por defecto
    return '$x'
  end

  -- Obtener el contenido de la línea siguiente (API usa índices base 0)
  local lines = vim.api.nvim_buf_get_lines(buf, next_line_num - 1, next_line_num, false)

  -- Comprobar si obtuvimos la línea
  if not lines or #lines == 0 then
    -- Error al obtener la línea, devolvemos el valor por defecto
    -- Podrías añadir un vim.notify aquí si quieres saber cuándo ocurre esto
    -- vim.notify("Error al obtener contenido de línea " .. next_line_num, vim.log.levels.WARN)
    return '$x'
  end
  local next_line_content = lines[1]

  -- Definir el patrón Lua para una variable PHP ($ seguido de caracteres de palabra)
  local pattern = '%$%w+'

  -- Buscar la primera ocurrencia del patrón en la línea siguiente
  -- string.find devuelve los índices de inicio y fin (base 1)
  local start_col, end_col = string.find(next_line_content, pattern)

  if start_col then
    -- Coincidencia encontrada, extraer el substring de la variable
    local found_variable = string.sub(next_line_content, start_col, end_col)
    return found_variable -- Devolver la variable encontrada
  else
    -- No se encontró coincidencia, devolver el valor por defecto
    return '$x'
  end
end

return {
  -- php tag
  s('php', fmt([[<?php {} ?>]], { i(0) })),

  -- strict type
  s('strict', t 'declare(strict_types=1);'),

  -- dd
  s('dd', fmt([[dd({});{}]], { i(1), i(0) })),

  -- dump
  s('dump', fmt([[dump({});{}]], { i(1), i(0) })),

  -- this
  s('$this', fmt([[$this->{}]], { i(0) })),

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

  -- if
  s(
    'if',
    fmta(
      [[
      if ($<exp>) {
      <sta>
      }
      ]],
      {
        exp = i(1),
        sta = i(0),
      }
    )
  ),

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

  -- trait
  s(
    'trait',
    fmt(
      [[
<?php

declare(strict_types=1);

namespace App\{};

{}

trait {}
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

  -- interface
  s(
    'interface',
    fmt(
      [[
<?php

declare(strict_types=1);

namespace App\{};

{}

interface {}
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

  -- test
  s(
    'it',
    fmt(
      [[
      it('{}', function (): void {{
      {}
      }});
]],
      {
        i(1),
        i(0),
      }
    )
  ),

  -- doc
  s(
    'doc',
    fmta(
      [[
      /**
       * <sta>
       */
      ]],
      {
        sta = i(0),
      }
    )
  ),

  -- variable phpstan
  s(
    'var',
    fmta(
      [[
      /** @var <type> <var> <comment> */
      ]],
      {
        type = i(1),
        var = f(next_var),
        comment = i(0),
      }
    )
  ),
}, {
  -- autosnippets
}
