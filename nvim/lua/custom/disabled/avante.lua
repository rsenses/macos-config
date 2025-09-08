vim.api.nvim_set_hl(0, 'MyAvanteCurrentGroup', {
  bg = '#2C363C',
  fg = '#EFEDEC',
  bold = true,
})

return {
  'yetone/avante.nvim',
  enabled = false,
  event = 'VeryLazy',
  version = false, -- Never set this value to "*"! Never!
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
  config = function()
    require('avante').setup {
      provider = 'gemini',
      gemini = {
        model = 'gemini-2.5-flash-preview-05-20',
        generationConfig = {
          thinkingConfig = {
            thinkingBudget = 1024,
          },
        },
      },
      selector = {
        provider = 'snacks',
      },
      highlights = {
        diff = {
          current = 'MyAvanteCurrentGroup',
        },
      },
      -- system_prompt as function ensures LLM always has latest MCP server state
      -- This is evaluated for every message, even in existing chats
      system_prompt = function()
        local hub = require('mcphub').get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ''
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require('mcphub.extensions.avante').mcp_tool(),
        }
      end,
      disabled_tools = {
        'list_files', -- Built-in file operations
        'search_files',
        'read_file',
        'create_file',
        'rename_file',
        'delete_file',
        'create_dir',
        'rename_dir',
        'delete_dir',
        'bash', -- Built-in terminal access
      },
    }
  end,
}
