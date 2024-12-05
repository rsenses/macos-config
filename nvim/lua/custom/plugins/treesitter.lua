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
      'nvim-treesitter/nvim-treesitter-textobjects',
      'windwp/nvim-ts-autotag',
    },
    config = function()
      require('nvim-treesitter.configs').setup {
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
        },
        modules = {},
        sync_install = true,
        auto_install = true,
        ignore_install = {},
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
      }

      local parser_config = require('nvim-treesitter.parsers').get_parser_configs()

      parser_config.blade = {
        install_info = {
          url = 'https://github.com/EmranMR/tree-sitter-blade',
          files = { 'src/parser.c' },
          branch = 'main',
        },
        filetype = 'blade',
      }

      vim.filetype.add {
        pattern = {
          ['.*%.blade%.php'] = 'blade',
        },
      }
    end,
  },
}
