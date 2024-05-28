vim.cmd [[
try
    colorscheme iceberg
    " colorscheme gruvbox
catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme default
endtry
]]

