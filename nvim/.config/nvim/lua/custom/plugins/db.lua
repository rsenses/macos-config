return {
  'tpope/vim-dadbod',
  cmd = { 'DB', 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  dependencies = {
    { 'kristijanhusak/vim-dadbod-ui' },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql', 'sqlite' } },
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_auto_execute_table_helpers = 1
    vim.g.db_ui_save_location = vim.fn.stdpath 'data' .. '/dadbod_queries'
    vim.g.db_ui_winwidth = 35
    vim.o.previewheight = 30
    vim.g.db_ui_show_help = 0

    -- vim.api.nvim_create_autocmd('FileType', {
    --   pattern = 'dbout',
    --   callback = function()
    --     vim.cmd 'resize 20'
    --   end,
    -- })

    -- Abre la UI automáticamente al añadir una conexión nueva
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_force_echo_notifications = 1

    local dbfile = vim.fn.getcwd() .. '/.db.lua'

    if vim.fn.filereadable(dbfile) == 1 then
      local ok, project_dbs = pcall(dofile, dbfile)
      if ok and type(project_dbs) == 'table' then
        vim.g.dbs = vim.tbl_extend('force', vim.g.dbs or {}, project_dbs)
      end
    end

    vim.g.db_ui_table_helpers = {
      mysql = {
        List = 'SELECT * FROM `{dbname}`.`{table}` ORDER BY id DESC LIMIT 200',
        Count = 'SELECT COUNT(*) AS total FROM `{dbname}`.`{table}`',
        ['Last 50'] = 'SELECT * FROM `{dbname}`.`{table}` ORDER BY id DESC LIMIT 50',
        ['Filter template'] = [[
SELECT *
FROM `{dbname}`.`{table}`
WHERE 1 = 1
LIMIT 200
]],
      },
      sqlite = {
        List = 'SELECT * FROM `{table}` ORDER BY id DESC LIMIT 200',
        Count = 'SELECT COUNT(*) AS total FROM `{table}`',
        ['Last 50'] = 'SELECT * FROM `{table}` ORDER BY id DESC LIMIT 50',
        ['Filter template'] = [[
SELECT *
FROM `{table}`
WHERE 1 = 1
LIMIT 200
]],
      },
    }

    vim.keymap.set('n', '<leader>du', '<cmd>DBUIToggle<cr>', { desc = 'Dadbod UI' })
    vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<cr>', { desc = 'Dadbod find buffer' })
    vim.keymap.set('n', '<leader>dr', '<cmd>DBUIRenameBuffer<cr>', { desc = 'Dadbod rename buffer' })
    vim.keymap.set('n', '<leader>dl', '<cmd>DBUILastQueryInfo<cr>', { desc = 'Dadbod last query info' })
  end,
}
