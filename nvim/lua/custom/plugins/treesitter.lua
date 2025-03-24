-- Highlight, edit, and navigate code
return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufRead', 'BufNewFile' },
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
      'nvim-treesitter/nvim-treesitter-textobjects',
      'windwp/nvim-ts-autotag',
      'nvim-treesitter/nvim-treesitter-context',
    },
    opts = {
      ensure_installed = {
        'c',
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
        'phpdoc',
        'scss',
        'yaml',
        'gitignore',
        'blade',
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
          init_selection = '<leader>cs',
          node_incremental = '<leader>cs',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
    },
    config = function(_, opts)
      ---@class parser_config
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

      require('nvim-treesitter.configs').setup(opts)

      require('treesitter-context').setup {}

      require('ts_context_commentstring').setup {
        enable_autocmd = false,
        languages = {
          php_only = '// %s',
          php = '// %s',
          blade = {
            __default = '// %s',
            html = '{{-- %s --}}',
            blade = '{{-- %s --}}',
            php = '// %s',
            php_only = '// %s',
          },
        },
        custom_calculation = function(_, language_tree)
          if vim.bo.filetype == 'blade' then
            if language_tree._lang == 'html' then
              return '{{-- %s --}}'
            end

            return '// %s'
          end
        end,
      }

      vim.filetype.get_option = function(filetype, option)
        return option == 'commentstring' and require('ts_context_commentstring.internal').calculate_commentstring() or vim.filetype.get_option(filetype, option)
      end
    end,
  },
}
