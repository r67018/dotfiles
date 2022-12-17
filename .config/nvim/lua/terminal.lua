local set = vim.keymap.set
local opts = { noremap = true, silent = true }
set('t', '<Esc>', [[<C-\><C-n>]], opts)                -- quit insert mode with ESC
set('n', '@t', '<cmd>tabe<CR><cmd>terminal<CR>', opts) -- open terminal in new tab

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
autocmd('TermOpen', {
    group = augroup('terminal', { clear = true }),
    callback = function ()
        local command = vim.api.nvim_command
        -- nonumber
        command('setlocal nonumber norelativenumber')
        -- start in insert mode
        command('startinsert')
    end
})

local create_cmd = vim.api.nvim_create_user_command
-- open terminal vertically with :T
create_cmd('T', 'vsplit | wincmd j | terminal <args>', { nargs = '*' })
-- open terminal horizontally with :Th
create_cmd('Th', 'split | wincmd j | resize 15 | terminal <args>', { nargs = '*' })

