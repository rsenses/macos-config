---@diagnostic disable: undefined-global

return {
  -- Html template
  s(
    'html',
    fmt(
      [[
    <!doctype html>
  <html lang="{}">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>{}</title>
      <link href="{}" rel="stylesheet" />
    </head>
    <body>
      {}
      <script src="{}"></script>
    </body>
  </html>
    ]],
      {
        i(1),
        i(2),
        i(3),
        i(0),
        i(4),
      }
    )
  ),
}
