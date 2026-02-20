-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- disable providers you don't need for faster startup
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- line number
vim.opt.relativenumber = false
vim.opt.number = true -- shows absolute line number on cursor

-- tabs & indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true -- expand tab to spaces
vim.opt.autoindent = true -- copy indent from current line

-- line wrapping
vim.opt.wrap = false

-- search settings
vim.opt.ignorecase = true -- ignore case when searching
vim.opt.smartcase = true -- if we include mixed case we use search case sensitive

-- cursor line
vim.opt.cursorline = true -- highlight current cursor line

-- appearance

-- turn on termguicolors for nightlyfy colorscheme to work
-- (needs a true color terminal)
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
vim.opt.backspace = "indent,eol,start" -- allow backspace on indent, eol or insert mode start position

-- clipboard
if vim.env.SSH_CONNECTION then
  vim.g.clipboard = "osc52"
end

vim.opt.clipboard:append("unnamedplus") -- use system clipboard as the default register

-- split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

-- folding (treesitter-based)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99 -- start with all folds open
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- turn off swapfile
vim.opt.swapfile = false

-- whitespace
vim.opt.list = true
local space = "·"
vim.opt.listchars = {
	tab = "→ ",
	multispace = space,
	lead = space,
	trail = space,
	nbsp = space,
  eol = "¬",
}
