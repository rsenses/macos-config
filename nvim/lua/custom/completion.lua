require 'custom.snippets'

local luasnip = require 'luasnip'

vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append 'c'

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

require('nvim-cmp-laravel').setup()

local cmp = require 'cmp'

cmp.setup {
  sources = {
    { name = 'nvim_lsp', priority = 1000, group_index = 1 },
    { name = 'luasnip', priority = 900, group_index = 2 },
    { name = 'copilot', priority = 800, group_index = 3 },
    { name = 'buffer', priority = 700, group_index = 4 },
    { name = 'path', priority = 600, group_index = 5 },
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
    ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
    ['<C-y>'] = cmp.mapping(
      cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      },
      { 'i', 'c' }
    ),
    ['<C-j>'] = cmp.mapping(function()
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        cmp.mapping.confirm { select = true }
      end
    end, { 'i', 's' }),
    ['<C-k>'] = cmp.mapping(function()
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        cmp.mapping.abort()
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
    ['<CR>'] = cmp.mapping.abort(),
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

  sorting = {
    priority_weight = 2,
    comparators = {
      require('copilot_cmp.comparators').prioritize,

      -- Below is the default comparitor list and order for nvim-cmp
      cmp.config.compare.offset,
      -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.locality,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
}
