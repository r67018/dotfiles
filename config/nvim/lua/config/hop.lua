require('hop').setup {
    keys = 'qweioasdghkl;fj',
}

local set = vim.keymap.set
local opts = { noremap = true,  silent = true }

set('n', '<Leader>w', '<cmd>HopWord<CR>', opts)
set('x', '<Leader>w', '<cmd>HopWord<CR>', opts)
set('n', '<Leader>l', '<cmd>HopLine<CR>', opts)
set('x', '<Leader>l', '<cmd>HopLine<CR>', opts)
set('n', '<Leader>s', '<cmd>HopChar2<CR>', opts)
set('x', '<Leader>s', '<cmd>HopChar2<CR>', opts)

