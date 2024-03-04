return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local luasnip = require("luasnip")
    local cmp = require("cmp")

    -- Elimina preselect y virtual text
    opts.preselect = cmp.PreselectMode.None
    opts.completion = {
      completeopt = "noselect",
    }
    opts.experimental = {
      ghost_text = false,
    }

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<C-n>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
          cmp.select_next_item()
        -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
        -- this way you will only jump inside the snippet region
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<C-p>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<C-y>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ["<CR>"] = cmp.config.disable,
    })
  end,
}
