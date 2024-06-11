require('nvim-treesitter.configs').setup {
    ensure_installed = {
        "c", "cpp", "rust", "python", "lua", "vim", "bash"
    },
    auto_intstall = true,

    highlight = {
        enable = true,
        disable = {},
    }
}

