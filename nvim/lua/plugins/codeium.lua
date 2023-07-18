return {
  "exafunction/codeium.vim",
  lazy = false,
  config = function()
    vim.g.codeium_disable_bindings = 1
    vim.keymap.set("i", "<C-c>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true })
    vim.keymap.set("i", "<C-n>", function()
      return vim.fn["codeium#CycleCompletions"](1)
    end, { expr = true })
    vim.keymap.set("i", "<C-p>", function()
      return vim.fn["codeium#CycleCompletions"](-1)
    end, { expr = true })
    vim.keymap.set("i", "<C-e>", function()
      return vim.fn["codeium#Clear"]()
    end, { expr = true })
    vim.g.codeium_no_map_tab = true
  end,
}
