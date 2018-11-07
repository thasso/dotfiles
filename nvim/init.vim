" vim:fdm=marker
" Plugins {{{
call plug#begin('~/.config/nvim/plugins')
" Color schemese
Plug 'flazz/vim-colorschemes'

" General plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-markdown'
Plug 'scrooloose/nerdcommenter'
Plug 'editorconfig/editorconfig-vim'
Plug 'airblade/vim-gitgutter'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tfnico/vim-gradle'
Plug 'dietsche/vim-lastplace'

" File and buffer completion
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'kien/ctrlp.vim'

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
" nmap <leader>k :OnlineThesaurusCurrentWord<CR>
" Buffer and file mappings
nnoremap <leader>t :FZF<CR>
nnoremap <leader>T :CtrlPBuffer<CR>

" Copy paste to system clipboard
set clipboard=unnamed
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

"function! s:buflist()
  "redir => ls
  "silent ls
  "redir END
  "return split(ls, '\n')
"endfunction

"function! s:bufopen(e)
  "execute 'buffer' matchstr(a:e, '^[ 0-9]*')
"endfunction

"nnoremap <silent> <F2> :call fzf#run({
"\   'source':  reverse(<sid>buflist()),
"\   'sink':    function('<sid>bufopen'),
"\   'options': '+m',
"\   'down':    len(<sid>buflist()) + 2
"\ })<CR>

"nnoremap <silent> <leader>T :call fzf#run({
"\   'source':  reverse(<sid>buflist()),
"\   'sink':    function('<sid>bufopen'),
"\   'options': '+m',
"\   'down':    len(<sid>buflist()) + 2
"\ })<CR>

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
" colorscheme base16-tomorrow
 colorscheme Tomorrow-Night
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
autocmd BufWritePre * :%s/\s\+$//e
" }}}
" GitGutter {{{
" Disable by default and use 'cog' to enable
let g:gitgutter_enabled = 0
" }}}
" podspec {{{
if has("autocmd")
  autocmd BufNewFile,BufRead Podfile,*.podspec set filetype=ruby
endif
" }}}
