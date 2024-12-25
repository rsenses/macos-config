-- Autocompletion
return {
  'L3MON4D3/LuaSnip',
  build = 'make install_jsregexp',
  event = 'InsertEnter',
  config = function()
    require 'custom.snippets'
  end,
}
