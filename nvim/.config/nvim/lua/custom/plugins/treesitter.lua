-- Highlight, edit, and navigate code
return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    branch = 'main',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-context',
      'windwp/nvim-ts-autotag',
    },
    config = function()
      local ts = require 'nvim-treesitter'

      local ensure_installed = {
        'blade',
        'css',
        'diff',
        'gitignore',
        'html',
        'javascript',
        'json',
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

      ts.install(ensure_installed)

      ts.setup {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }

      -- 3) Workaround mínimo: arranque del highlighter por FileType
      local group = vim.api.nvim_create_augroup('TreesitterStart', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(ev)
          -- evita buffers especiales
          local bt = vim.bo[ev.buf].buftype
          if bt ~= '' then
            return
          end

          -- arranca TS (si ya estaba arrancado, no pasa nada)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })

      require('treesitter-context').setup {
        enable = true,
      }

      require('mini.comment').setup {
        options = {
          custom_commentstring = function()
            local ok, parser = pcall(vim.treesitter.get_parser, 0)
            if not ok or not parser then
              return nil
            end

            local ft = vim.bo.filetype
            local curline = vim.fn.line '.' - 1
            local ok2, langobj = pcall(parser.language_for_range, parser, { curline, 0, curline, 0 })
            if not ok2 or not langobj then
              return nil
            end
            local lang = langobj:lang()
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

      require('nvim-ts-autotag').setup {
        opts = {
          -- Defaults
          enable_close = false, -- Auto close tags
          enable_rename = true, -- Auto rename pairs of tags
          enable_close_on_slash = false, -- Auto close on trailing </
        },
        aliases = {
          ['blade'] = 'html',
        },
        per_filetype = {
          ['html'] = {
            enable_close = true, -- Auto close tags
            enable_rename = true, -- Auto rename pairs of tags
            enable_close_on_slash = true,
          },
        },
      }
    end,
  },
}
