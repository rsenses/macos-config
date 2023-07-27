return -- add more treesitter parsers
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      emmet_ls = {
        filetypes = {
          "css",
          "html",
          "javascript",
          "javascriptreact",
          "less",
          "sass",
          "scss",
          "svelte",
          "typescriptreact",
          "vue",
          "php",
          "blade",
        },
      },
      stylelint_lsp = {
        filetypes = {
          "css",
          "scss",
          "less",
          "sass",
        },
      },
    },
  },
}
