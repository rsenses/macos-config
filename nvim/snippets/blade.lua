---@diagnostic disable: undefined-global

return {
  -- php
  s(
    'php',
    fmta(
      [[
      @php
      <sta>
      @endphp
      ]],
      {
        sta = i(0),
      }
    )
  ),

  -- if
  s(
    'if',
    fmta(
      [[
      @if (<exp>)
      <sta>
      @endif
      ]],
      {
        exp = i(1),
        sta = i(0),
      }
    )
  ),

  -- if else
  s(
    'else',
    fmta(
      [[
      @if (<exp>)
      <sta>
      @else
      <sta2>
      @endif
      ]],
      {
        exp = i(1),
        sta = i(2),
        sta2 = i(0),
      }
    )
  ),

  -- if ternary
  s(
    'iif',
    fmta(
      [[
      {{ <exp> ? <sta> : <sta2> }}
      ]],
      {
        exp = i(1),
        sta = i(2),
        sta2 = i(0),
      }
    )
  ),

  -- foreach
  s(
    'foreach',
    fmta(
      [[
      @foreach ($<exp> as $<val>)
      <sta>
      @endforeach
      ]],
      {
        exp = i(1),
        val = i(2),
        sta = i(0),
      }
    )
  ),
}
