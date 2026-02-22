-- Basic settings
vim.g.loaded_netrw = 1 -- I do not use netrw
vim.g.loaded_netrwPlugin = 1 -- I do not use netrw
vim.opt.number = true -- shows absolute line number on cursor
vim.opt.relativenumber = false -- line number
vim.opt.wrap = false -- no wrapping by default
vim.opt.cursorline = true -- highlight current cursor line
vim.opt.scrolloff = 10 -- keep X lines above/below cursor
vim.opt.sidescrolloff = 8 -- keep X characters left/right of cursor
vim.opt.backspace = "indent,eol,start" -- allow backspace on indent, eol or insert mode start position

-- tabs & indentation
vim.opt.tabstop = 2 -- Tab width
vim.opt.shiftwidth = 2 -- Indent width
vim.opt.softtabstop = 2 -- soft tab stop
vim.opt.expandtab = true -- expand tab to spaces
vim.opt.autoindent = true -- copy indent from current line
vim.opt.smartindent = true -- Smart auto-indenting

-- search settings
vim.opt.ignorecase = true -- ignore case when searching
vim.opt.smartcase = true -- if we include mixed case we use search case sensitive
vim.opt.hlsearch = true -- search highlighting by default
vim.opt.incsearch = true -- show matches as I type

-- appearance
vim.opt.termguicolors = true -- turn on more colors
vim.opt.signcolumn = "auto" -- show sign column only when needed
vim.opt.showmatch = true -- highlight matching brackets
vim.opt.matchtime = 2 -- for how long are matching brackets shown
vim.opt.showmode = false -- custom status line will handle this
vim.opt.conceallevel = 0 -- Don't hide markup
vim.opt.concealcursor = "" -- Don't hide cursor line markup
vim.opt.list = true -- show whitespace characters (see below)
local space = "·"
vim.opt.listchars = {
	tab = "→ ",
	multispace = space,
	lead = space,
	trail = space,
	nbsp = space,
	eol = "¬",
}

-- file handling
vim.opt.swapfile = false -- turn off swapfile
vim.opt.backup = false -- no need for backup files
vim.opt.writebackup = false -- don't create a backup before writing
vim.opt.autoread = true -- auto reload files that changed
vim.opt.autowrite = false -- no auto save

-- behavior
vim.g.clipboard = "osc52" -- use OSC52 as the main clipboard. Let's me copy into system clipboard over ssh
vim.opt.clipboard:append("unnamedplus") -- use system clipboard as the default register
vim.opt.encoding = "UTF-8"

-- spell checking
vim.opt.spelllang = { "en_us" }
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

-- split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

-- folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99 -- start with all folds open
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
