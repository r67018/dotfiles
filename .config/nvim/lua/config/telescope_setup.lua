local set = vim.keymap.set
local opts = { noremap = true, silent = true }

set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', opts)
set('n', '<leader>fF', '<cmd>Telescope frecency<cr>', opts)
set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', opts)
set('n', '<leader>fb', '<cmd>Telescope buffers<cr>', opts)
set('n', '<leader>fc', '<cmd>Telescope commands<cr>', opts)
set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', opts)

