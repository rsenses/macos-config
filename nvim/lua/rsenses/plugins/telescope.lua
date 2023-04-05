return {
    {
        "nvim-telescope/telescope.nvim",
        lazy = false,
        tag = "0.1.0",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-fzf-native.nvim",    build = "make" },
            { 'nvim-telescope/telescope-live-grep-args.nvim' },
        },
        config = function()
            -- You dont need to set any of these options. These are the default ones. Only
            -- the loading is important
            local actions = require('telescope.actions')

            require("telescope").setup {
                defaults = {
                    path_display = { truncate = 1 },
                    prompt_prefix = '   ',
                    selection_caret = '  ',
                    layout_config = {
                        prompt_position = 'top',
                    },
                    sorting_strategy = 'ascending',
                    mappings = {
                        i = {
                            ['<esc>'] = actions.close,
                            ['<C-Down>'] = actions.cycle_history_next,
                            ['<C-Up>'] = actions.cycle_history_prev,
                        },
                    },
                    file_ignore_patterns = {
                        "node_modules",
                        "vendor",
                        "build",
                        "dist",
                        '.git/'
                    }
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    buffers = {
                        previewer = false,
                        layout_config = {
                            width = 80,
                        },
                    },
                    oldfiles = {
                        prompt_title = 'History',
                    },
                    lsp_references = {
                        previewer = false,
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
                    }
                }
            }

            -- To get fzf loaded and working with telescope, you need to call
            -- load_extension, somewhere after setup function:
            require("telescope").load_extension("fzf")
            require('telescope').load_extension('live_grep_args')

            -- Telescope Keymaps
            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find,
                { desc = "[/] Search current buffer" })
            vim.keymap.set('n', '<leader>pF', [[<cmd>lua require('telescope.builtin').find_files({ no_ignore = true, prompt_title = 'All Files' })<CR>]], { desc = "[F]ind all files" }) -- luacheck: no max line length
            vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "[F]ind files" })
            vim.keymap.set("n", "<leader>pg", builtin.live_grep, { desc = "[G]rep find" })
            vim.keymap.set("n", "<leader><space>", builtin.buffers, { desc = "[B]uffers find" })
            vim.keymap.set("n", "<leader>pw", builtin.lsp_workspace_symbols, { desc = "[W]orkspace symbols" })
            vim.keymap.set("n", "<leader>ps", builtin.lsp_document_symbols, { desc = "[D]ocument symbols" })
            vim.keymap.set("n", "<leader>pc", builtin.git_bcommits, { desc = "[C]ommits current buffer" })
            vim.keymap.set("n", "<leader>pC", builtin.git_commits, { desc = "[C]ommits" })
            vim.keymap.set("i", "<C-r>", builtin.registers, { desc = "[R]egisters" })
            vim.keymap.set("n", "<leader>vd", builtin.diagnostics, { desc = "[D]iagnostics" })
            vim.keymap.set("n", "<leader>vh", builtin.help_tags, { desc = "[H]elp tags" })
            vim.keymap.set("n", "<leader>vm", builtin.man_pages, { desc = "[M]an pages" })
        end
    }
}
