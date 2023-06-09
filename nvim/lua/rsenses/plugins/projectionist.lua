return {
    {
        'tpope/vim-projectionist',
        requires = 'tpope/vim-dispatch',
        lazy = true,
        ft = 'php',
        config = function()
            vim.g.projectionist_heuristics = {
                artisan = {
                    ['app/Models/*.php'] = {
                        type = 'model',
                    },
                    ['app/Http/Controllers/*.php'] = {
                        type = 'controller',
                    },
                    ['routes/*.php'] = {
                        type = 'route',
                    },
                    ['database/migrations/*.php'] = {
                        type = 'migration',
                    },
                    ['app/*.php'] = {
                        type = 'source',
                        alternate = {
                            'tests/Unit/{}Test.php',
                            'tests/Feature/{}Test.php',
                        },
                    },
                    ['tests/Feature/*Test.php'] = {
                        type = 'test',
                        alternate = 'app/{}.php',
                    },
                    ['tests/Unit/*Test.php'] = {
                        type = 'test',
                        alternate = 'app/{}.php',
                    },
                },
            }
        end,
    }
}
