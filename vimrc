set nocompatible
set encoding=utf-8
set spelllang=en_us
set whichwrap+=<,>,h,l
set so=7
set number
set undolevels=1000
set nobackup
set nowritebackup
set noswapfile
set hlsearch
set ignorecase
set smartcase
set magic
set list
set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮
set nocursorline
set mouse=a
set showmatch
set mat=2
set expandtab
set linebreak
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set wrap
set colorcolumn=80,120
highlight ColorColumn ctermbg=237
augroup markdownSpell
    autocmd!
    autocmd FileType markdown setlocal spell
    autocmd BufRead,BufNewFile *.md setlocal spell
    autocmd FileType text setlocal spell
    autocmd BufRead,BufNewFile *.txt setlocal spell
    autocmd FileType gitcommit setlocal spell
augroup END

nnoremap <SPACE> <Nop>
let mapleader=" "
noremap <leader>y "+y
noremap <leader>p "+p
