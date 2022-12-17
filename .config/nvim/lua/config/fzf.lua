require('fzf-lua').setup {
    winopts = {
        height     = 0.85,
        width      = 0.80,
        row        = 0.35,
        col        = 0.50,
        border     = 'rounded',
        rullscreen = false,
    }
}

local set  = vim.keymap.set
local opts = { noremap = true, silent = true }

set('n', '<Leader>o', '<cmd>FzfLua files<CR>', opts)
set('n', '<Leader>p', '<cmd>FzfLua grep<CR>', opts)
set('n', '<Leader>/', '<cmd>FzfLua blines<CR>', opts)
set('n', '<Leader>g', '<cmd>FzfLua git_status<CR>', opts)

