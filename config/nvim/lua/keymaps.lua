local opts = { noremap = true, silent = true }

local set = vim.keymap.set

-- leader
set('', '<Space>', '<Nop>', opts)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '


-- Modes
--   normal_mode = 'n',
--   insert_mode = 'i',
--   visual_mode = 'v',
--   visual_block_mode = 'x',
--   term_mode = 't',
--   command_mode = 'c',

-- Normal --
-- new line
set('n', '<CR>', 'o<Esc>', opts)
set('n', '<Tab><CR>', 'O<Esc>', opts)

-- buffer
set('n', '[b', ':bprev<CR>', opts)
set('n', ']b', ':bnext<CR>', opts)

-- :noh with esc x 2
set('n', '<esc><esc>', '<cmd>nohlsearch<cr>', opts)

-- don't use register
set('n', 'x', '"_x', opts)
set('n', 's', '"_s', opts)

-- Insert --
-- remap right
set('i', '<C-]>', '<Right>', opts)

-- replace the previous 2 charaters
set('i', '<C-t>', '<Esc><Left>"zx"zpa', opts)

