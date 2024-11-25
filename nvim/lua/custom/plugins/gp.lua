return {
  'robitx/gp.nvim',
  config = function()
    local conf = {
      openai_api_key = 'bogus', -- must be set to avoid errors
      whisper = {
        disable = true,
      },
      providers = {
        openai = {
          disable = true,
        },
        copilot = {
          disable = false,
          endpoint = 'https://api.githubcopilot.com/chat/completions',
          secret = {
            'bash',
            '-c',
            "cat ~/.config/github-copilot/hosts.json | sed -e 's/.*oauth_token...//;s/\".*//'",
          },
        },
      },
      agents = {
        {
          chat = false,
          command = true,
          disable = false,
          model = { model = 'gpt-4', temperature = 0.8, top_p = 1, n = 1 },
          name = 'CodeCopilot',
          provider = 'copilot',
          system_prompt = require('gp.defaults').code_system_prompt,
        },
      },
    }
    require('gp').setup(conf)
    vim.keymap.set('v', '<leader>ar', ":<C-u>'<,'>GpRewrite<cr>", { desc = 'Rewrite selection' })
  end,
}
