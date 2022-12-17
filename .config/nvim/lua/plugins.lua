local fn = vim.fn

-- automatically install packer
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		'git',
		'clone',
		'--depth',
		'1',
		'https://github.com/wbthomason/packer.nvim',
		install_path,
	})
	print('Installing packer close and reopen Neovim...')
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
-- vim.cmd([[
--   augroup packer_user_config
--     autocmd!
--     autocmd BufWritePost plugins.lua source <afile> | PackerSync
--   augroup end
-- ]])

-- use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
	return
end

-- have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require('packer.util').float({ border = 'rounded' })
		end,
	},
})

-- install your plugins here
return packer.startup(function(use)
    use 'wbthomason/packer.nvim'

    -- colorschemes --
    use 'cocopon/iceberg.vim' -- theme
    use 'vim-airline/vim-airline' -- awesome status bar
    use 'vim-airline/vim-airline-themes' -- status bar themes

    -- utility --
    -- pair off parentheses
    use {
        'windwp/nvim-autopairs',
        config = function() require('nvim-autopairs').setup {} end,
        event = 'InsertEnter',
    }

    -- easy to move
    use {
        'phaazon/hop.nvim',
        branch = 'v2', -- official recommendation
        config = [[require('config.hop')]],
    }

    -- comment
    use {
        'numToStr/Comment.nvim',
        config = function() require('Comment').setup {} end,
        event = 'VimEnter',
    }

    -- align
    use {
        'junegunn/vim-easy-align',
        event = 'VimEnter',
    }

    -- surround text
    use {
        'kylechui/nvim-surround',
        config = function() require('nvim-surround').setup {} end,
        event = 'VimEnter',
    }

    -- trim whitespace
    use {
        'cappyzawa/trim.nvim',
        config = [[require('config.trim')]],
        event = 'BufWrite',
    }

    -- file explorer
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons', -- for file icons
        },
        config = [[require('config.tree')]]
    }

    -- completion --
    use {
        'hrsh7th/nvim-cmp',
        requires = {
            { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
            'hrsh7th/cmp-nvim-lsp',
            { 'hrsh7th/cmp-path', after = 'nvim-cmp'},
            { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp'},
        },
        config = [[require('config.cmp')]],
        event = 'VimEnter',
    }
    -- lsp
    use {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'neovim/nvim-lspconfig',
    }
    -- snippet
    use {
        'L3MON4D3/LuaSnip',
        tag = 'v<CurrentMajor>.*',
        event = 'InsertEnter',
    }
    -- pretty
    use {
        'folke/trouble.nvim',
        requires = 'kyazdani42/nvim-web-devicons',
        config = [[require('config.trouble')]],
        event = 'VimEnter',
    }

    -- fuzzy finder --
    use {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.0',
        requires = {
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
            { 'nvim-telescope/telescope-frecency.nvim', after = 'telescope.nvim', requires = 'tami5/sqlite.lua' },
        },
        wants = {
            'plenary.nvim',
            'telescope-fzf-native.nvim',
            'telescope-frecency.nvim',
        },
        setup  = [[require('config.telescope_setup')]],
        config = [[require('config.telescope')]],
        cmd    = 'Telescope',
        module = 'telescope',
    }
    -- use {
    --     'nvim-telescope/telescope-frecency.nvim',
    --     after = 'nvim-telescope/telescope.nvim',
    --     requires = {
    --         'tami5/sqlite.lua',
    --     },
    -- }

    -- automatically set up your configuration after cloning packer.nvim
	-- put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require('packer').sync()
    end
end)

