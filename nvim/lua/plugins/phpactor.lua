return {
  {
    "gbprod/phpactor.nvim",
    ft = { "php", "yaml" },
    cmd = { "PhpActor" },
    keys = {
      { "<leader>cp", ":PhpActor context_menu<cr>", desc = "PhpActor context menu" },
    },
    build = function()
      require("phpactor.handler.update")()
    end,
    opts = {
      install = {
        check_on_startup = "daily",
        bin = vim.fn.stdpath("data") .. "/mason/bin/phpactor",
      },
      lspconfig = {
        enabled = true,
        init_options = {
          ["language_server_phpstan.enabled"] = true,
          ["phpunit.enabled"] = true,
        },
      },
    },
  },
}
