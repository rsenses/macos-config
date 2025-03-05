-- Autocompletion
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    'nvim-lua/plenary.nvim',
    'onsails/lspkind.nvim',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-git',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'adoolaard/nvim-cmp-laravel',
    'zbirenbaum/copilot.lua',
    'zbirenbaum/copilot-cmp',
  },
  config = function()
    local lspkind = require 'lspkind'
    lspkind.init {
      symbol_map = {
        Copilot = '',
      },
    }

    vim.api.nvim_set_hl(0, 'CmpItemKindCopilot', { fg = '#6600ff' })
    vim.api.nvim_set_hl(0, 'CmpItemKindSnippet', { fg = '#ec5353' })
    vim.api.nvim_set_hl(0, 'CmpItemKindBuffer', { fg = '#000000' })
    vim.api.nvim_set_hl(0, 'CmpItemKindPath', { fg = '#e4e831' })

    local kind_formatter = lspkind.cmp_format {
      mode = 'symbol_text',
      menu = {
        buffer = '[buf]',
        nvim_lsp = '[lsp]',
        nvim_lua = '[api]',
        path = '[path]',
        luasnip = '[snip]',
        gh_issues = '[issues]',
        copilot = '[copilot]',
      },
    }

    require('copilot_cmp').setup()
    require('nvim-cmp-laravel').setup()

    local cmp = require 'cmp'
    local luasnip = require 'luasnip'

    cmp.setup {
      completion = { completeopt = 'menu,menuone,noinsert' },
      sources = {
        { name = 'luasnip', priority = 1000, group_index = 1 },
        { name = 'nvim_lsp', priority = 900, group_index = 2 },
        { name = 'buffer', priority = 850, group_index = 3 },
        { name = 'render-markdown', priority = 850, group_index = 3 },
        { name = 'copilot', priority = 800, group_index = 4 },
        { name = 'path', priority = 600, group_index = 6 },
        { name = 'nvim_lsp_signature_help', priority = 600, group_index = 6 },
        {
          name = 'lazydev',
          group_index = 0,
        },
      },
      mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-y>'] = cmp.mapping(
          cmp.mapping.confirm {
            select = true,
          },
          { 'i', 'c' }
        ),
        ['<Tab>'] = cmp.mapping(function()
          if luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function()
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
        ['<C-e>'] = cmp.mapping(function()
          if luasnip.choice_active() then
            luasnip.change_choice(1)
          else
            cmp.mapping.abort()
          end
        end, { 'i', 's' }),
        ['<C-s>'] = cmp.mapping.complete {},
        ['<CR>'] = cmp.config.disable,
      },

      -- Enable luasnip to handle snippet expansion for nvim-cmp
      snippet = {
        expand = function(args)
          vim.snippet.expand(args.body)
        end,
      },

      formatting = {
        fields = { 'abbr', 'kind', 'menu' },
        expandable_indicator = true,
        format = function(entry, vim_item)
          -- Lspkind setup for icons
          vim_item = kind_formatter(entry, vim_item)

          return vim_item
        end,
      },
    }
  end,
}
