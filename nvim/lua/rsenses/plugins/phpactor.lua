return {
  {
    'phpactor/phpactor',
    branch = 'master',
    lazy = true,
    ft = 'php',
    run = 'composer install --no-dev -o',
    config = function()
      vim.cmd([[
        augroup PhpactorMappings
          au!
          au FileType php nmap <buffer> <Leader>vp :PhpactorContextMenu<CR>
          au FileType php nmap <buffer> <Leader>vn :PhpactorClassNew<CR>
        augroup END
      ]])

      vim.cmd [[
        augroup phpactor
          autocmd!
          autocmd FileType php setlocal iskeyword+=\$ formatoptions-=cro
          autocmd BufWritePre * %s/\s\+$//e
          autocmd TextYankPost * silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=400})
          autocmd VimResized * tabdo wincmd =
        augroup END
      ]]
    end,
  }
}
