local cmp = require'cmp'

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
    },
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        -- { name = 'vsnip' }, -- For vsnip users.
        { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
        { name = 'buffer' },
        { name = 'path' },
    })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
        { name = 'buffer' },
    })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
})

-- lsp setting
local on_attach = function(client, bufnr)
    -- disable formatting
    client.server_capabilities.documentFormattingProvider = false

    local set = vim.keymap.set
    local opts = { noremap = true, silent = true }
    -- set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
    -- set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
    set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
    -- set("n", "<C-m>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
    -- set("n", "gy", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
    set("n", "rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
    set("n", "ma", "<cmd>lua vim.lsp.buf.code_action()<CR>")
    -- set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
    set("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>")
    set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
    set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>")

    -- telescope
    set('n', '<Leader>r', '<cmd>Telescope lsp_references<CR>', opts)
    set('n', '<Leader>d', '<cmd>Telescope lsp_definitions<CR>', opts)
    set('n', '<Leader>D', '<cmd>Telescope lsp_type_definitions<CR>', opts)
    set('n', '<Leader>i', '<cmd>Telescope lsp_implementations<CR>', opts)
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- setup language servers installed with mason.nvim
require("mason").setup()
require("mason-lspconfig").setup()
require("mason-lspconfig").setup_handlers {
    function (server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup {
            on_attach = on_attach, -- register function to be called when attaching
            capabilities = capabilities, -- link with cmp
        }
    end,
}

require('lspconfig').lua_ls.setup {
    settings = {
        Lua = {
            diagnostics = {
                -- get the lsp to recognize the 'vim' as global variable
                globals = { 'vim' },
            },
        },
    },
}

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
        -- disable to show error messages on the line.
        virtual_text = false,
    }
)

