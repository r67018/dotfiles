local options = {
	-- editor
    swapfile = false,
	equalalways = false,
    number = true,
    relativenumber = true,
	wrap = false,
	wildmenu = true,
	list = false,
	splitbelow = true,
	splitright = true,
	-- search
	hlsearch = true,
	incsearch = true,
	ignorecase = true,
	smartcase = true,
	wrapscan = true,
	-- cursor
	ruler = true,
	whichwrap = "b,s,h,l,[,],<,>,~",
	cursorline = true,
    guicursor = "i:block",
    -- color
    termguicolors = true,
	-- tab
	expandtab = true,
	tabstop = 4,
	shiftwidth = 4,
	smartindent = true,
	autoindent = true,
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

