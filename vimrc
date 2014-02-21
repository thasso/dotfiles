" vim:fdm=marker
" Base setting {{{
set nocompatible
filetype off
" Vundle setup {{{
let install_bundles=0
let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
    echo "Installing Vundle..."
    echo ""
    silent !mkdir -p ~/.vim/bundle
    silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
    let install_bundles=1
endif
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
" }}}
" }}}
" Bundles {{{

Bundle 'gmarik/vundle'

Bundle 'bling/vim-airline'
Bundle 'kien/ctrlp.vim'
Bundle 'tpope/vim-fugitive'
"Bundle 'ervandew/supertab'
Bundle 'scrooloose/nerdcommenter'
Bundle 'scrooloose/syntastic'
Bundle 'majutsushi/tagbar'
Bundle 'klen/python-mode'
Bundle 'nono/vim-handlebars'
Bundle 'chriskempson/base16-vim'
Bundle 'haya14busa/vim-easymotion'
Bundle 'tomtom/tlib_vim.git'
Bundle 'MarcWeber/vim-addon-mw-utils.git'
Bundle 'garbas/vim-snipmate'
Bundle 'honza/vim-snippets.git'
Bundle 'tfnico/vim-gradle'
Bundle 'Shougo/neocomplcache.vim'
Bundle 'davidhalter/jedi-vim'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-repeat'

" tmux pane navigation
Bundle 'christoomey/vim-tmux-navigator'

Bundle 'thasso/vim-jip'
" }}}
" General setting {{{
"execute pathogen#infect()
filetype plugin indent on
syntax on
if !has('gui_running')
    set term=screen-256color
endif
set hidden
set spelllang=en_US
set modelines=1
" set backspace=2
" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" auto read file when changed on disk
set autoread
set number
set history=700
set undolevels=700
" no backup and swap files
set nobackup
set nowritebackup
set noswapfile

" search
set nohlsearch
set incsearch
set ignorecase
set smartcase
" For regular expressions turn magic on
set magic

" display tabs and end of lines
set list
set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮
" highlight current line
set cursorline
set completeopt=menu,preview,longest
set wildmenu
set wildmode=list:longest:full
set mouse=a
" Don't redraw while executing macros (good performance config)
set lazyredraw

"Always show current position
set ruler

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" enable "+ as default register
" note that we need the yank remaps below
if $TMUX == ''
    set clipboard=unnamedplus
endif

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif
" Remember info about open buffers on close
set viminfo^=%

" load .vimrc automatically on changes
if has("autocmd")
  autocmd! bufwritepost .vimrc source %
endif
" }}}
" Leader bindings {{{
let mapleader = ","
imap jj <esc>l
nmap <Leader>e :cnext<CR>
nmap <Leader>E :cprevious<CR>
nmap <Leader>ev :vsplit $MYVIMRC<CR>
nmap <Leader>n :bn<CR>
nmap <Leader>m :bp<CR>
nmap <Leader>s :set spell!<CR>
nmap <leader>p gqip " wrap paragraph
"nmap <leader>T :LustyBufferExplorer<CR>
nmap <leader>w :w<CR>
nmap <leader>q :q<CR>
nmap <leader>P :PyLintToggle<CR>
nmap <leader>T :LustyBufferExplorer<CR>
nmap <leader>fa zM
nmap <leader>fu zR
nmap <leader>l :TagbarToggle<CR>
nnoremap <silent> <Leader>xt :CommandT<CR>
nnoremap <leader>t :CtrlP<CR>
nnoremap <leader>T :CtrlPBuffer<CR>
nmap <leader>h :set hlsearch! hlsearch? <CR>
" }}}
" Keybindings {{{
" Treat long lines as break lines (useful when moving around in them)
map j gj
map k gk
imap <C-h> <left>
imap <C-l> <right>
imap <C-j> <down>
imap <C-k> <up>
imap <C-e> <esc>$a
imap <C-a> <esc>^i
imap <C-s> <esc>:wi<CR>
nmap <C-s> :w<CR>
nmap <space> za
imap <S-down> <esc>vj
nmap <S-down> <esc>vj
vmap <S-down> j
imap <S-up> <esc>vk
nmap <S-up> <esc>vk
vmap <S-up> k
nmap <S-right> <esc>vl
imap <S-right> <esc>vl
vmap <S-up> l
nmap <S-left> <esc>vh
imap <S-left> <esc>vh
vmap <S-up> h
imap <C-space> <C-X><C-O>
nmap <F3> :cnext<CR>
nmap <S-F3> :cprevious<CR>
imap <F3> <esc>:cnext<CR>
imap <S-F3> <esc>:cprevious<CR>
" select paste text
nnoremap gp `[v`]
" go to end of selection after yank
" and always do a normal yank and a yank to system clipboard
" vmap y y`]
nnoremap yy yy"+yy
vnoremap y ygv"+y`]
" aliases
:command! W w
"
" }}}
" Window navigation {{{
nmap <c-j> <c-w>j
nmap <c-k> <c-w>k
nmap <c-l> <c-w>l
nmap <c-h> <c-w>h
" }}}
" File wildcards {{{
set wildignore+=*.pyc,*.o,*.obj,.git,*.egg/**,*.min.js,*.so,*egg-info*/**,*.jpg,*.png,*.gif,*.ico
" }}}
" Color scheme {{{
set background=dark
let base16colorspace=256
colorscheme base16-chalk
set colorcolumn=80
highlight ColorColumn ctermbg=235
" }}}
" GUI Mode {{{
if has('gui_running')
    set guioptions-=T " disable toolbar
    set guioptions-=m " disable menu
    set guifont=Source\ Code\ Pro\ for\ Powerline
    set guioptions+=LlRrb
    set guioptions-=LlRrb
endif
" }}}
" Tabs, Spaces, and Wrap {{{
set expandtab
set linebreak
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set wrap
" }}}
" Folding and custom fold line {{{
function! NeatFoldText()
  let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
  let lines_count = v:foldend - v:foldstart + 1
  let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
  let foldchar = matchstr(&fillchars, 'fold:\zs.')
  let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
  let foldtextend = lines_count_text . repeat(foldchar, 8)
  let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
  return foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
endfunction
set foldtext=NeatFoldText()
" }}}
" File types and settings {{{
" Python {{{
if has("autocmd")
  autocmd Filetype python setlocal expandtab
  autocmd Filetype python set foldmethod=indent foldlevel=99
endif
" }}}
" C {{{
if has("autocmd")
  autocmd Filetype c setlocal expandtab
  autocmd Filetype c setlocal shiftwidth=2
  autocmd Filetype c setlocal softtabstop=2
  autocmd Filetype c setlocal tabstop=2
  autocmd Filetype c set foldmethod=syntax foldlevel=99 foldlevel=99
endif

" }}}
" HTML {{{
if has("autocmd")
  autocmd Filetype html setlocal expandtab
  autocmd Filetype html setlocal shiftwidth=2
  autocmd Filetype html setlocal softtabstop=2
  autocmd Filetype html setlocal tabstop=2
  autocmd Filetype html setlocal cindent
  "let g:html_indent_inctags = "html,body,head,tbody"
  let g:html_indent_inctags = "body,head,tbody"
  let g:syntastic_html_tidy_ignore_errors=[" proprietary attribute \"ng-"]

  autocmd Filetype html set foldmethod=syntax foldlevel=99 foldlevel=99
endif
" }}}
" }}}
" Plugin Settings {{{
" Powerline {{{
"set rtp+=~/.vim/bundle/powerline/powerline/bindings/vim
set laststatus=2
"set noshowmode
"  }}}
" Airline {{{
let g:airline_powerline_fonts = 1
" }}}
"  Command T {{{
let g:CommandTMatchWindowAtTop=1
let g:CommandTMaxHeight=20
"  }}}
" CtrlP {{{
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)|node_modules$|bower_components',
  \ 'file': '\v\.(exe|so|dll)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }
" }}}
" Mark Multiple {{{
"let g:mark_multiple_trigger = "<C-d>"
"nmap <C-d> :call MarkMultiple()<CR>
"xmap <C-d> :call MarkMultiple()<CR>
"nmap <C-N> :call MarkMultipleClean()<CR>
"xmap <C-N> :call MarkMultipleClean()<CR>
" }}}
" Expand Regions {{{
"nmap <C-w> viw<Plug>(expand_region_expand)
imap <C-w> <esc>viw<Plug>(expand_region_expand)
vmap <C-W> <Plug>(expand_region_expand)
" }}}
" Tagbar {{{
"let g:tagbar_ctags_bin='~/usr/bin/ctags'
" }}}
" Python Mode {{{
let g:pymode_rope_guess_project=0
let g:pymode_rope=0

" }}}
"{{{ JEDI
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#popup_on_dot = 0
let g:jedi#popup_select_first = 1
let g:jedi#auto_initialization = 1

" hide docstring while completing
autocmd FileType python setlocal completeopt-=preview
"}}}
"{{{ Go Lang
set runtimepath+=$GOROOT/misc/vim
" }}}
" {{{ Snipmate
imap <C-J> <esc>a<Plug>snipMateNextOrTrigger
smap <C-J> <Plug>snipMateNextOrTrigger
" }}}
" {{{ NeoComplCache
let g:neocomplcache_enable_at_startup = 1
" TAB completion
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
      let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplcache_omni_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplcache_omni_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'


"  }}}
"  tmux navigator {{{
"let g:tmux_navigator_no_mappings = 1
"  }}}
 " }}}
" Vundle install {{{ 
if install_bundles == 1
    echo "Installing Bundles, please ignore key map error messages"
    echo ""
    :BundleInstall
endif
" }}}
