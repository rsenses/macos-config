return {
  {
    -- Make sure to set this up properly if you have lazy=true
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
    opts = {
      file_types = { 'markdown' },
      completions = { lsp = { enabled = true }, blink = { enabled = true } },
    },
    ft = { 'markdown' },
  },
  {
    'tjdevries/present.nvim',
    enable = false,
  },
}
