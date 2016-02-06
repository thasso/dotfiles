" vim:fdm=marker
" Plugins {{{
call plug#begin('~/.config/nvim/plugins')
" Color schemese
Plug 'chriskempson/base16-vim'

" General plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-markdown'
Plug 'bling/vim-airline'
Plug 'scrooloose/nerdcommenter'
Plug 'editorconfig/editorconfig-vim'
Plug 'airblade/vim-gitgutter'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tfnico/vim-gradle'
Plug 'dietsche/vim-lastplace'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'haya14busa/incsearch.vim'
Plug 'flazz/vim-colorschemes'
Plug 'reedes/vim-pencil'
Plug 'reedes/vim-colors-pencil'

" Add plugins to &runtimepath
call plug#end()
" }}}
" General {{{
" Default spell check language
set spelllang=en_us
" Show line numbers by default
set number
" Increase undo levels
set undolevels=1000
" no backup and swap files
set nobackup
set nowritebackup
set noswapfile
" Hide search result hightlighting by default
set nohlsearch
" Ignore case and use smart case for searches
set ignorecase
set smartcase
" For regular expressions turn magic on
set magic
" display tabs and end of lines
set list
set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮
" Command line mode completion enables and iterate with tab
set wildmenu
set wildmode=longest:full,full
" Mouse mode enabled
set mouse=a
" " Show matching brackets when text indicator is over them
set showmatch
" " How many tenths of a second to blink when matching brackets
set mat=2
" Remember info about open buffers on close
set viminfo^=%
" Render color column at 80
set colorcolumn=80
" Ignore patterns
set wildignore+=*.pyc,*.o,*.obj,.git,*.egg/**,*.min.js,*.so,*egg-info*/**,*.jpg,*.png,*.gif,*.ico
" dected *.md files as markdown
autocmd BufNewFile,BufRead *.md set filetype=markdown
" }}}
" Leader bindings {{{
let mapleader = "\<space>"
nmap <leader>w :w<CR>
nmap <leader>q :q<CR>
" Buffer and file mappings
nnoremap <leader>t :FZF<CR>
" Copy paste to system clipboard
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" " }}}
" Keybindings {{{
" Emacs style beginnig and end of line in insert mode
imap <C-e> <esc>$a
imap <C-a> <esc>^i
" select paste text
nnoremap gp `[v`]
" go to end of selection after yank
vmap y ygv<Esc>
" " use some unused function key codes to
" " make special key combos work in terminal
map  <F13> <M-Up>
map  <F14> <M-Down>

nmap <silent> cog :GitGutterToggle<CR>
" }}}
" Color scheme {{{
set background=dark
let base16colorspace=256
colorscheme base16-tomorrow
highlight ColorColumn ctermbg=235
" }}}
" Tabs, Spaces, and Wrap {{{
set expandtab
set linebreak
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set wrap
" Delete trailing whitespace
" autocmd BufWritePre * :%s/\s\+$//e
" }}}
" Airline {{{
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='base16'
" }}}
" GitGutter {{{
" Disable by default and use 'cog' to enable
let g:gitgutter_enabled = 0
" }}}
" Incsearch {{{
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
" }}}
" podspec {{{
if has("autocmd")
  autocmd BufNewFile,BufRead Podfile,*.podspec set filetype=ruby
endif
" }}}
" vim Pencil {{{
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
  autocmd FileType text         call pencil#init()
  autocmd Filetype git,gitsendemail,*commit*,*COMMIT* call pencil#init({'wrap': 'hard', 'textwidth': 72})
  let g:pencil_terminal_italics = 1
  let g:airline_section_x = '%{PencilMode()}'
augroup END
" }}}
