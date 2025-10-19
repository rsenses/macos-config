-- Highlight, edit, and navigate code
return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufRead', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-context',
    },
    opts = {
      ensure_installed = {
        -- 'c',
        -- 'bash',
        'html',
        'lua',
        'diff',
        'markdown',
        'markdown_inline',
        -- 'query',
        'vim',
        'vimdoc',
        'css',
        'javascript',
        'json',
        'vue',
        'php',
        -- 'php_only',
        'phpdoc',
        'scss',
        'yaml',
        'gitignore',
        'blade',
        -- 'regex',
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
      require('nvim-treesitter.configs').setup(opts)

      require('treesitter-context').setup {}

      require('mini.comment').setup {
        options = {
          custom_commentstring = function()
            local curline = vim.fn.line '.'
            local ft = vim.bo.filetype
            local lang = vim.treesitter.get_parser():language_for_range({ curline, 0, curline, 0 }):lang()
            -- vim.print(lang)
            if ft == 'blade' then
              if lang == 'php' or lang == 'php_only' or lang == 'javascript' then
                return '// %s'
              elseif lang == 'css' then
                return '/* %s */'
              end
              return '{{-- %s --}}'
            elseif ft == 'php' then
              return '// %s'
            else
              return nil
            end
          end,
        },
      }
    end,
  },
}
