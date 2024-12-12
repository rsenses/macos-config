-- Autocompletion
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-git',
    {
      'L3MON4D3/LuaSnip',
      config = function()
        require('luasnip.loaders.from_lua').load {
          paths = { vim.fn.stdpath 'config' .. '/snippets' },
        }
        require('luasnip').filetype_extend('php', { 'blade', 'phpdoc' })
      end,
      keys = function()
        return {}
      end,
      build = 'make install_jsregexp',
    },
    'saadparwaiz1/cmp_luasnip',
    'adoolaard/nvim-cmp-laravel',
  },
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    luasnip.config.setup {}

    local kind_icons = {
      Text = ' ',
      Method = ' ',
      Function = ' 󰊕',
      Constructor = ' ',
      Copilot = ' ',
      Field = ' ﴲ ',
      Variable = ' $',
      Class = ' ',
      Interface = ' ',
      Module = ' 󰕳',
      Property = ' ',
      Unit = ' ',
      Value = ' ',
      Enum = ' ',
      Keyword = ' ',
      Snippet = ' ',
      Color = ' 󰌁',
      File = ' ',
      Reference = ' ',
      Folder = ' ',
      EnumMember = ' ',
      Constant = ' ﲀ',
      Struct = ' ﳤ',
      Event = '  ',
      Operator = ' ',
      TypeParameter = ' 󰼭',
    }

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
          -- vim.snippet.expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone,noinsert' },

      -- For an understanding of why these mappings were
      -- chosen, you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-y>'] = cmp.mapping.confirm { select = true },
        ['<C-j>'] = cmp.mapping(function()
          if luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's' }),
        ['<C-k>'] = cmp.mapping(function()
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
        vim.keymap.set({ 'i', 's' }, '<C-e>', function()
          if luasnip.choice_active() then
            luasnip.change_choice(1)
          else
            cmp.mapping.abort()
          end
        end, { silent = true }),
        ['<C-s>'] = cmp.mapping.complete {},
        ['<CR>'] = cmp.mapping.abort(),
      },

      sources = {
        { name = 'nvim_lsp', priority = 1000, group_index = 1 },
        { name = 'luasnip', priority = 900, group_index = 2 },
        { name = 'copilot', priority = 800, group_index = 3 },
        { name = 'buffer', priority = 700, group_index = 4 },
        { name = 'path', priority = 600, group_index = 5 },
      },

      view = {
        entries = 'native', -- or custom
      },
      formatting = {
        -- here is where the change happens
        format = function(entry, vim_item)
          vim_item.kind = kind_icons[vim_item.kind]
          vim_item.menu = ({
            buffer = '[buf]',
            path = '[path]',
            nvim_lsp = '[lsp]',
            luasnip = '[snip]',
            cmdline = '[cmd]',
            copilot = '[cop]',
            nvim_lua = '[lua]',
          })[entry.source.name]
          return vim_item
        end,
      },
    }

    require('nvim-cmp-laravel').setup()
  end,
}
