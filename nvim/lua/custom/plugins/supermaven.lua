-- Autocompletion
return {
  'supermaven-inc/supermaven-nvim',
  dependencies = {
    {
      'saghen/blink.compat',
      version = '*',
      opts = {
        impersonate_nvim_cmp = true,
        debug = true,
      },
    },
  },
  opts = {
    disable_inline_completion = true,
    disable_keymaps = true,
  },
}
