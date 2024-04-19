return {
  'vim-test/vim-test',
  cmd = {
    'TestNearest',
    'TestFile',
    'TestSuite',
    'TestLast',
    'TestVisit',
  },
  keys = {
    { '<leader>tt', '<cmd>TestNearest<cr>', desc = 'Run nearest test' },
    { '<leader>tT', '<cmd>TestFile<cr>', desc = 'Run current file' },
    { '<leader>ta', '<cmd>TestSuite<cr>', desc = 'Run all tests' },
    { '<leader>tl', '<cmd>TestLast<cr>', desc = 'Run last test' },
    { '<leader>tg', '<cmd>TestVisit<cr>', desc = 'Go to test file' },
  },
}
