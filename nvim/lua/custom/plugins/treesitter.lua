-- Highlight, edit, and navigate code
return {
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufRead', 'BufNewFile' },
    dependencies = {
      {
        'EmranMR/tree-sitter-blade',
        config = function()
          -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
          local parser_config = require('nvim-treesitter.parsers').get_parser_configs()

          parser_config.blade = {
            install_info = {
              url = 'https://github.com/EmranMR/tree-sitter-blade',
              files = { 'src/parser.c' },
              branch = 'main',
            },
            filetype = 'blade',
          }

          -- Filetypes --
          vim.filetype.add {
            pattern = {
              ['.*%.blade%.php'] = 'blade',
            },
          }
        end,
      },
      'nvim-treesitter/nvim-treesitter-textobjects',
      'windwp/nvim-ts-autotag',
    },
    opts = {
      ensure_installed = {
        'bash',
        'html',
        'lua',
        'diff',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'css',
        'javascript',
        'json',
        'vue',
        'php',
        'php_only',
        'scss',
        'yaml',
        'gitignore',
        'blade',
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      autotag = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<c-space>',
          node_incremental = '<c-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
    },
  },
}
