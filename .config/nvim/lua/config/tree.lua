require('nvim-tree').setup {
    filters = {
        dotfiles = true,
    },
}

local set = vim.keymap.set
local opts = { noremap = true, silent = true }

set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', opts)

