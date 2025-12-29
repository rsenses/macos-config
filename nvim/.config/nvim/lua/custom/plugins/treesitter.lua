-- Highlight, edit, and navigate code
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    event = { 'BufRead', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-context',
    },
    config = function()
      local ts = require 'nvim-treesitter'

      -- Install core parsers at startup
      ts.install {
        'blade',
        'css',
        'diff',
        'gitignore',
        'html',
        'javascript',
        'json',
        'jsx',
        'lua',
        'markdown',
        'markdown_inline',
        'php',
        'phpdoc',
        'scss',
        'vim',
        'vimdoc',
        'vue',
        'yaml',
      }

      local group = vim.api.nvim_create_augroup('TreesitterSetup', { clear = true })

      local ignore_filetypes = {
        'checkhealth',
        'lazy',
        'ministarter',
        'mininotify-history',
      }

      -- Auto-install parsers and enable highlighting on FileType
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        desc = 'Enable treesitter highlighting and indentation',
        callback = function(event)
          if vim.tbl_contains(ignore_filetypes, event.match) then
            return
          end

          local lang = vim.treesitter.language.get_lang(event.match) or event.match
          local buf = event.buf

          -- Start highlighting immediately (works if parser exists)
          pcall(vim.treesitter.start, buf, lang)

          -- Enable treesitter indentation
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- Install missing parsers (async, no-op if already installed)
          ts.install { lang }
        end,
      })

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
