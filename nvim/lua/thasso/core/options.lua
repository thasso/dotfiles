vim.cmd("let g:netrw_liststyle=3")

local opt=vim.opt

-- line numberes
opt.relativenumber = false
opt.number = true -- shows absolute line number on cursor

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line

-- line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if we include mixed case we use search case sensitive

-- cursor line
opt.cursorline = true -- highlight current cursor line

-- appearance

-- turn on termguicolors for nightlyfy colorscheme to work
-- (needs a true color terminal)
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, eol or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use sustem clipboard as teh default register

-- split windows
opt.splitright = true
opt.splitbelow = true

-- turn off swapfile
opt.swapfile = false


