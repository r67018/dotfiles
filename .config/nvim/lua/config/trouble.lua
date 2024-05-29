require('trouble').setup {

}

local set = vim.keymap.set
local opts = { noremap = true, silent = true }

set('n', '<Leader>xx', '<cmd>TroubleClose<CR> <cmd>TroubleClose<CR>', opts)
set('n', '<Leader>xw', '<cmd>TroubleClose<CR> <cmd>Trouble workspace_diagnostics<CR>', opts)
set('n', '<Leader>xd', '<cmd>TroubleClose<CR> <cmd>Trouble document-diagnostics<CR>', opts)
set('n', '<Leader>xq', '<cmd>TroubleClose<CR> <cmd>Trouble quickfix<CR>', opts)
set('n', '<Leader>xl', '<cmd>TroubleClose<CR> <cmd>Trouble loclist<CR>', opts)

