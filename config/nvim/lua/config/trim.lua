require('trim').setup {
    disable = { 'markdown' },
    trim_last_line = false,
    patterns = {
        [[%s/\n*\%$/\r/]],        -- leave a single line at end of file
    },
}

