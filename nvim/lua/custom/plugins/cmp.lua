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
        require('luasnip.loaders.from_vscode').lazy_load {
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
    -- See `:help cmp`
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
      -- completion = { completeopt = 'menu,menuone,noselect' },
      completion = { completeopt = 'menu,menuone,noinsert' },
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

      -- For an understanding of why these mappings were
      -- chosen, you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      mapping = cmp.mapping.preset.insert {
        -- Select the [n]ext item
        ['<C-n>'] = cmp.mapping.select_next_item(),
        -- Select the [p]revious item
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        -- scroll the documentation window [b]ack / [f]orward
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        -- Accept ([y]es) the completion.
        --  This will auto-import if your LSP supports it.
        --  This will expand snippets if the LSP sent a snippet.
        ['<C-y>'] = cmp.mapping.confirm { select = true },
        -- Manually trigger a completion from nvim-cmp.
        --  Generally you don't need this, because nvim-cmp will display
        --  completions whenever it has completion options available.
        ['<C-Space>'] = cmp.mapping.complete {},
        -- Think of <c-l> as moving to the right of your snippet expansion.
        --  So if you have a snippet that's like:
        --  function $name($args)
        --    $body
        --  end
        --
        -- <c-l> will move you to the right of each of the expansion locations.
        -- <c-h> is similar, except moving you backwards.
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
        ['<C-e>'] = cmp.mapping.abort(),
      },

      --    the order of your sources matter (by default). That gives them priority
      --    you can configure:
      --        keyword_length
      --        priority
      --        max_item_count
      --        (more?)
      sources = {
        { name = 'copilot' },
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'buffer' },
      },
      -- sorting = {
      --   comparators = {
      --     cmp.config.compare.exact,
      --     cmp.config.compare.score,
      --     cmp.config.compare.recently_used,
      --     cmp.config.compare.locality,
      --     cmp.config.compare.offset,
      --
      --     -- copied from cmp-under, but I don't think I need the plugin for this.
      --     -- I might add some more of my own.
      --     function(entry1, entry2)
      --       local _, entry1_under = entry1.completion_item.label:find '^_+'
      --       local _, entry2_under = entry2.completion_item.label:find '^_+'
      --       entry1_under = entry1_under or 0
      --       entry2_under = entry2_under or 0
      --       if entry1_under > entry2_under then
      --         return false
      --       elseif entry1_under < entry2_under then
      --         return true
      --       end
      --     end,
      --
      --     cmp.config.compare.kind,
      --   },
      -- },
    }

    require('nvim-cmp-laravel').setup()
  end,
}
