return {
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
          "phtml",
          "twig",
          "blade",
          "html.twig",
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
      phpactor = {
        filetypes = {
          "php",
        },
      },
    },
  },
}
