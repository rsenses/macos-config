return {
  settings = {
    Lua = {
      workspace = {
        library = { vim.env.VIMRUNTIME, vim.fn.stdpath 'config' },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
}
