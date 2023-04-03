-- Autocommands

local augroup = vim.api.nvim_create_augroup
local rsensesGroup = augroup('rsenses', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = rsensesGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Activate spell on some filetypes
autocmd("FileType", {
    pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
    callback = function()
        vim.opt_local.spell = true
    end,
})

-- resize splits if window got resized
autocmd({ "VimResized" }, {
    callback = function()
        vim.cmd "tabdo wincmd ="
    end,
})

-- stop automatic newline comment
autocmd({ "BufEnter" }, {
    pattern = "*",
    callback = function()
        vim.cmd "set formatoptions-=cro"
    end,
})
autocmd({ "BufEnter" }, {
    pattern = "*",
    callback = function()
        vim.cmd "setlocal formatoptions-=cro"
    end,
})
