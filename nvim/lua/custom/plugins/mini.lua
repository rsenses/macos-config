return {
  'echasnovski/mini.nvim',
  config = function()
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- Add surrounding with sa (in visual mode or on motion).
    -- Delete surrounding with sd.
    -- Replace surrounding with sr.
    -- Find surrounding with sf or sF (move cursor right or left).
    -- Highlight surrounding with sh.
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup { n_lines = 500 }

    -- "gS" to toggle splitjoin on objects, arrays, etc.
    require('mini.splitjoin').setup()

    require('mini.files').setup {
      mappings = {
        go_in_plus = '<CR>',
        go_out_plus = '-',
      },
      windows = {
        preview = true,
        width_focus = 40,
        width_preview = 80,
      },
    }

    vim.keymap.set('n', '-', function()
      require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
    end, { desc = 'Open Mini Files' })

    vim.api.nvim_create_autocmd('User', {
      -- Updated pattern to match what Echasnovski has in the documentation
      -- https://github.com/echasnovski/mini.nvim/blob/c6eede272cfdb9b804e40dc43bb9bff53f38ed8a/doc/mini-files.txt#L508-L529
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id
        -- Import 'mini.files' module
        local mini_files = require 'mini.files'
        -- Ensure opts.custom_keymaps exists

        -- Copy the current file or directory to the lamw25wmal system clipboard
        -- NOTE: This works only on macOS
        vim.keymap.set('n', '<leader>yy', function()
          -- Get the current entry (file or directory)
          local curr_entry = mini_files.get_fs_entry()
          if curr_entry then
            local path = curr_entry.path
            -- Escape the path for shell command
            local escaped_path = vim.fn.fnameescape(path)
            -- Build the osascript command to copy the file or directory to the clipboard
            local cmd = string.format([[osascript -e 'set the clipboard to POSIX file "%s"' ]], escaped_path)
            local result = vim.fn.system(cmd)
            if vim.v.shell_error ~= 0 then
              vim.notify('Copy failed: ' .. result, vim.log.levels.ERROR)
            else
              vim.notify(vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
              vim.notify('Copied to system clipboard', vim.log.levels.INFO)
            end
          else
            vim.notify('No file or directory selected', vim.log.levels.WARN)
          end
        end, { buffer = buf_id, noremap = true, silent = true, desc = 'Copy file/directory to clipboard' })

        -- ZIP current file or directory and copy to the system clipboard
        vim.keymap.set('n', '<leader>yz', function()
          local curr_entry = mini_files.get_fs_entry()
          if curr_entry then
            local path = curr_entry.path
            local name = vim.fn.fnamemodify(path, ':t') -- Extract the file or directory name
            local parent_dir = vim.fn.fnamemodify(path, ':h') -- Get the parent directory
            local timestamp = os.date '%y%m%d%H%M%S' -- Append timestamp to avoid duplicates
            local zip_path = string.format('/tmp/%s_%s.zip', name, timestamp) -- Path in macOS's tmp directory
            -- Create the zip file
            local zip_cmd = string.format('cd %s && zip -r %s %s', vim.fn.shellescape(parent_dir), vim.fn.shellescape(zip_path), vim.fn.shellescape(name))
            local result = vim.fn.system(zip_cmd)
            if vim.v.shell_error ~= 0 then
              vim.notify('Failed to create zip file: ' .. result, vim.log.levels.ERROR)
              return
            end
            -- Copy the zip file to the system clipboard
            local copy_cmd = string.format([[osascript -e 'set the clipboard to POSIX file "%s"' ]], vim.fn.fnameescape(zip_path))
            local copy_result = vim.fn.system(copy_cmd)
            if vim.v.shell_error ~= 0 then
              vim.notify('Failed to copy zip file to clipboard: ' .. copy_result, vim.log.levels.ERROR)
              return
            end
            vim.notify(zip_path, vim.log.levels.INFO)
            vim.notify('Zipped and copied to clipboard: ', vim.log.levels.INFO)
          else
            vim.notify('No file or directory selected', vim.log.levels.WARN)
          end
        end, { buffer = buf_id, noremap = true, silent = true, desc = 'Zip and copy to clipboard' })

        -- Paste the current file or directory from the system clipboard into the current directory in mini.files
        -- NOTE: This works only on macOS
        vim.keymap.set('n', '<leader>p', function()
          -- vim.notify("Starting the paste operation...", vim.log.levels.INFO)
          if not mini_files then
            vim.notify('mini.files module not loaded.', vim.log.levels.ERROR)
            return
          end
          local curr_entry = mini_files.get_fs_entry() -- Get the current file system entry
          if not curr_entry then
            vim.notify('Failed to retrieve current entry in mini.files.', vim.log.levels.ERROR)
            return
          end
          local curr_dir = curr_entry.fs_type == 'directory' and curr_entry.path or vim.fn.fnamemodify(curr_entry.path, ':h') -- Use parent directory if entry is a file
          -- vim.notify("Current directory: " .. curr_dir, vim.log.levels.INFO)
          local script = [[
            tell application "System Events"
              try
                set theFile to the clipboard as alias
                set posixPath to POSIX path of theFile
                return posixPath
              on error
                return "error"
              end try
            end tell
          ]]
          local output = vim.fn.system('osascript -e ' .. vim.fn.shellescape(script)) -- Execute AppleScript command
          if vim.v.shell_error ~= 0 or output:find 'error' then
            vim.notify('Clipboard does not contain a valid file or directory.', vim.log.levels.WARN)
            return
          end
          local source_path = output:gsub('%s+$', '') -- Trim whitespace from clipboard output
          if source_path == '' then
            vim.notify('Clipboard is empty or invalid.', vim.log.levels.WARN)
            return
          end
          local dest_path = curr_dir .. '/' .. vim.fn.fnamemodify(source_path, ':t') -- Destination path in current directory
          local copy_cmd = vim.fn.isdirectory(source_path) == 1 and { 'cp', '-R', source_path, dest_path } or { 'cp', source_path, dest_path } -- Construct copy command
          local result = vim.fn.system(copy_cmd) -- Execute the copy command
          if vim.v.shell_error ~= 0 then
            vim.notify('Paste operation failed: ' .. result, vim.log.levels.ERROR)
            return
          end
          -- vim.notify("Pasted " .. source_path .. " to " .. dest_path, vim.log.levels.INFO)
          mini_files.synchronize() -- Refresh mini.files to show updated directory content
          vim.notify('Pasted successfully.', vim.log.levels.INFO)
        end, { buffer = buf_id, noremap = true, silent = true, desc = 'Paste from clipboard' })

        -- Copy the current file or directory path (relative to home) to clipboard
        vim.keymap.set('n', '<leader>yp', function()
          -- Get the current entry (file or directory)
          local curr_entry = mini_files.get_fs_entry()
          if curr_entry then
            -- Convert path to be relative to home directory
            local home_dir = vim.fn.expand '~'
            local relative_path = curr_entry.path:gsub('^' .. home_dir, '~')
            vim.fn.setreg('+', relative_path) -- Copy the relative path to the clipboard register
            vim.notify(vim.fn.fnamemodify(relative_path, ':t'), vim.log.levels.INFO)
            vim.notify('Path copied to clipboard: ', vim.log.levels.INFO)
          else
            vim.notify('No file or directory selected', vim.log.levels.WARN)
          end
        end, { buffer = buf_id, noremap = true, silent = true, desc = 'Copy relative path to clipboard' })
      end,
    })

    -- Movement helpers, for example ciq to change inside quotes, cib to change inside brackets, etc.
    require('mini.ai').setup()

    -- Autopairs
    require('mini.pairs').setup {
      mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\]%W' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\]%W' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\]%W' },

        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\]%W' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\]%W' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\]%W' },

        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\]%W', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\]%W', register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\]%W', register = { cr = false } },
      },
    }

    -- GitSigns
    require('mini.diff').setup {
      view = {
        -- Signs used for hunks with 'sign' view
        signs = { add = ' ', change = '󰏫 ', delete = '󰆴 ' },
      },
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Apply hunks inside a visual/operator region
        apply = 'gh',

        -- Reset hunks inside a visual/operator region
        reset = 'gH',

        -- Hunk range textobject to be used inside operator
        -- Works also in Visual mode if mapping differs from apply and reset
        textobject = 'gh',

        -- Go to hunk range in corresponding direction
        goto_first = '[H',
        goto_prev = '[h',
        goto_next = ']h',
        goto_last = ']H',
      },
    }

    -- Highlight colors and TODOs
    local hipatterns = require 'mini.hipatterns'
    hipatterns.setup {
      highlighters = {
        vim.cmd [[
            highlight MiniHipatternsFixme guifg=Black guibg=NvimLightRed gui=bold
            highlight MiniHipatternsHack guifg=Black guibg=NvimLightYellow gui=bold
            highlight MiniHipatternsTodo guifg=Black guibg=NvimLightCyan gui=bold
            highlight MiniHipatternsNote guifg=Black guibg=NvimLightGreen gui=bold
        ]],

        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
        hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = hipatterns.gen_highlighter.hex_color(),
      },
    }

    local miniclue = require 'mini.clue'
    miniclue.setup {
      triggers = {
        -- Leader triggers
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },

        -- Built-in completion
        { mode = 'i', keys = '<C-x>' },

        -- `g` key
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },

        -- Marks
        { mode = 'n', keys = "'" },
        { mode = 'n', keys = '`' },
        { mode = 'x', keys = "'" },
        { mode = 'x', keys = '`' },

        -- Registers
        { mode = 'n', keys = '"' },
        { mode = 'x', keys = '"' },
        { mode = 'i', keys = '<C-r>' },
        { mode = 'c', keys = '<C-r>' },

        -- Window commands
        { mode = 'n', keys = '<C-w>' },

        -- `z` key
        { mode = 'n', keys = 'z' },
        { mode = 'x', keys = 'z' },

        -- Brackets
        { mode = 'n', keys = '[' },
        { mode = 'n', keys = ']' },
        { mode = 'x', keys = '[' },
        { mode = 'x', keys = ']' },
      },

      clues = {
        -- Enhance this by adding descriptions for <Leader> mapping groups
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),

        -- Descriptions
        { mode = 'n', keys = '<leader>a', desc = '[A]i' },
        { mode = 'n', keys = '<leader>b', desc = '[B]uffers' },
        { mode = 'n', keys = '<leader>c', desc = '[C]ode' },
        { mode = 'n', keys = '<leader>cp', desc = '[C]ode PHP' },
        { mode = 'n', keys = '<leader>e', desc = '[E]ditor' },
        { mode = 'n', keys = '<leader>es', desc = '[S]pelling' },
        { mode = 'n', keys = '<leader>esl', desc = '[L]anguage' },
        { mode = 'n', keys = '<leader>g', desc = '[G]it' },
        { mode = 'n', keys = '<leader>s', desc = '[S]earch' },
        { mode = 'n', keys = '<leader>w', desc = '[W]indows' },
      },

      window = {
        config = {
          anchor = 'SE' --[[ bottom right ]],
          row = 'auto',
          col = 'auto',
          width = 'auto',
        },
        delay = 500,
        -- Keys to scroll inside the clue window
        scroll_down = '<C-n>',
        scroll_up = '<C-p>',
      },
    }
  end,
}
