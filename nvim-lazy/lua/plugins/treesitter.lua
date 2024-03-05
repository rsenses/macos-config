return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.ensure_installed = {
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "php",
      "regex",
      "typescript",
      "vim",
      "yaml",
      "css",
      "gitignore",
      "scss",
    }

    require("nvim-treesitter.configs").setup(opts)
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.blade = {
      install_info = {
        url = "https://github.com/EmranMR/tree-sitter-blade",
        files = { "src/parser.c" },
        branch = "main",
      },
      filetype = "blade",
    }
  end,
}
