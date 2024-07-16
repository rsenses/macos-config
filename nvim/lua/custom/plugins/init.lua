-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  --  This is equivalent to:
  --    require('gitsigns').setup({})

  -- Add a dependency to those plugins, then it will get loaded before the plugins get loaded.
  -- This is a way of load those plugins with kind of order/priority

  {
    'jwalton512/vim-blade',
    enabled = false,
  },
  'tpope/vim-repeat',
}
