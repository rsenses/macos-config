return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.0",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }
        },
        config = function()
            -- You dont need to set any of these options. These are the default ones. Only
            -- the loading is important
            require("telescope").setup {
                defaults = {
                    file_ignore_patterns = {
                        "node_modules",
                        "vendor",
                        "build",
                        "dist",
                        ".git"
                    }
                },
                extensions = {
                    fzf = {
                        fuzzy = true,               -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true, -- override the file sorter
                        case_mode = "smart_case",   -- or "ignore_case" or "respect_case"
                    }
                }
            }
            -- To get fzf loaded and working with telescope, you need to call
            -- load_extension, somewhere after setup function:
            require("telescope").load_extension("fzf")

            -- Telescope
            vim.keymap.set("n", "<leader>/", require("telescope.builtin").current_buffer_fuzzy_find,
            { desc = "[/] Search current buffer" })
            vim.keymap.set("n", "<leader>pf", require("telescope.builtin").find_files, { desc = "[F]ind files" })
            vim.keymap.set("n", "<leader>pg", require("telescope.builtin").live_grep, { desc = "[G]rep find" })
            vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[B]uffers find" })
            vim.keymap.set("n", "<leader>pw", require("telescope.builtin").lsp_workspace_symbols,
            { desc = "[W]orkspace symbols" })
            vim.keymap.set("n", "<leader>ps", require("telescope.builtin").lsp_document_symbols,
            { desc = "[D]ocument symbols" })
            vim.keymap.set("n", "<leader>pc", require("telescope.builtin").git_bcommits,
            { desc = "[C]ommits current buffer" })
            vim.keymap.set("n", "<leader>pC", require("telescope.builtin").git_commits, { desc = "[C]ommits" })
            vim.keymap.set("i", "<C-r>", require("telescope.builtin").registers, { desc = "[R]egisters" })
            vim.keymap.set("n", "<leader>vd", require("telescope.builtin").diagnostics, { desc = "[D]iagnostics" })
            vim.keymap.set("n", "<leader>vh", require("telescope.builtin").help_tags, { desc = "[H]elp tags" })
            vim.keymap.set("n", "<leader>vm", require("telescope.builtin").man_pages, { desc = "[M]an pages" })
        end
    }
}
