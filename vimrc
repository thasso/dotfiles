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
" }}}
" }}}
" Bundles {{{
call vundle#begin()

" General and utilities
Plugin 'tpope/vim-sensible'
Plugin 'bling/vim-airline'
" Color themes
Plugin 'chriskempson/base16-vim'
Plugin 'morhetz/gruvbox'
Plugin 'NLKNguyen/papercolor-theme'
Plugin 'therubymug/vim-pyte'
Plugin 'vim-scripts/summerfruit256.vim'

Plugin 'editorconfig/editorconfig-vim'
Plugin 'kien/ctrlp.vim'
Plugin 'haya14busa/incsearch.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-eunuch'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'honza/vim-snippets' " These are some default snipets
Plugin 'SirVer/ultisnips' " This is the snippets plugin, below are the snippets
Plugin 'Lokaltog/vim-easymotion'
Plugin 'terryma/vim-expand-region'

Plugin 'rking/ag.vim'
Plugin 'rbgrouleff/bclose.vim' " Use Bclose to close a buffer but keep the window
Plugin 'airblade/vim-gitgutter'
Plugin 'jiangmiao/auto-pairs'

Plugin 'tpope/vim-dispatch'
Plugin 'tpope/vim-projectionist'

"" GIT and SCM
Plugin 'tpope/vim-fugitive'

"" Formatting and completion
Plugin 'rhysd/vim-clang-format'
Plugin 'Valloric/YouCompleteMe'
Plugin 'scrooloose/syntastic'
Plugin 'davidhalter/jedi-vim'

"" tmux pane navigation
Plugin 'christoomey/vim-tmux-navigator'

"" Languages
Plugin 'thasso/vim-jip'
Plugin 'tfnico/vim-gradle'
Plugin 'fatih/vim-go.git'

" Javascript
Plugin 'marijnh/tern_for_vim'
Plugin 'pangloss/vim-javascript'
Plugin 'nathanaelkane/vim-indent-guides'

" Markdown preview
Plugin 'greyblake/vim-preview'
" Fix python indentation to be pep8 compatible
Plugin 'hynek/vim-python-pep8-indent'

" Text and prose writing (and dependencies)
Plugin 'kana/vim-textobj-user'
Plugin 'kana/vim-textobj-line'
Plugin 'reedes/vim-pencil'
Plugin 'reedes/vim-lexical'
Plugin 'reedes/vim-litecorrect'
Plugin 'reedes/vim-textobj-quote'
Plugin 'reedes/vim-textobj-sentence'

" One vim instance
Plugin 'reedes/vim-one'
" TExt objects
Plugin 'michaeljsmith/vim-indent-object'
Plugin 'tpope/vim-vinegar'
Plugin 'wellle/targets.vim'

call vundle#end()
" }}}
" General setting {{{
" Note that the sensible plugin already sets lots of defaults
set encoding=utf-8
" Color settings
set t_Co=256
if !has('gui_running')
    set term=screen-256color
endif
" Default spell check language
set spelllang=en_us
" whichrap here ensures that navigation left/right goes to next/previous line
set whichwrap+=<,>,h,l
" Set 7 lines to the cursor - when moving vertically using j/k
set so=7
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
" highlight current line
set cursorline
" Command line mode completion enables and iterate with tab
set wildmenu
set wildmode=longest:full,full
" Mouse mode enabled
set mouse=a
" " Show matching brackets when text indicator is over them
set showmatch
" " How many tenths of a second to blink when matching brackets
set mat=2

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exec "normal! g`\"" |
     \ endif
" Remember info about open buffers on close
set viminfo^=%
" Render color column at 80
set colorcolumn=80
" Ignore patterns
set wildignore+=*.pyc,*.o,*.obj,.git,*.egg/**,*.min.js,*.so,*egg-info*/**,*.jpg,*.png,*.gif,*.ico
" dected *.md files as markdown
autocmd BufNewFile,BufRead *.md set filetype=markdown

" Make sure that pasting over a selected region does not overwrite the
" default past buffer
function! RestoreRegister()
  let @" = s:restore_reg
  return ''
endfunction
function! s:Repl()
  let s:restore_reg = @"
  return "p@=RestoreRegister()\<cr>"
endfunction
vmap <silent> <expr> p <sid>Repl()

" " }}}
" Color scheme {{{
set background=dark
let base16colorspace=256
" colorscheme base16-chalk
" colorscheme base16-ashes
colorscheme base16-tomorrow
" colorscheme gruvbox
highlight ColorColumn ctermbg=235
" }}}
" GUI Mode {{{
if has('gui_running')
    set guioptions-=T " disable toolbar
    set guioptions-=m " disable menu
    set guioptions-=rL " disable scrollbar
    set guifont=Source\ Code\ Pro\ for\ Powerline
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
" Delete trailing whitespace
autocmd BufWritePre * :%s/\s\+$//e
" }}}
" Leader bindings {{{
let mapleader = "\<space>"
nmap <leader>w :w<CR>
nmap <leader>q :q<CR>
" Show - XXX toggles
nmap <leader>ss :set spell!<CR>
nmap <leader>sh :set hlsearch! hlsearch? <CR>
" Folding
nmap <leader>fa zM
nmap <leader>fu zR
nmap <leader>ff za
" Buffer and file mappings
nnoremap <leader>T :CtrlPBuffer<CR>
nnoremap <leader>t :CtrlP<CR>
" Copy paste to system clipboard
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" " }}}
" Keybindings {{{
map j gj
map k gk
imap jj <esc>l
" Emacs style beginnig and end of line in insert mode
imap <C-e> <esc>$a
imap <C-a> <esc>^i
" select paste text
nnoremap gp `[v`]
" go to end of selection after yank
vmap y ygv<Esc>
" Git commands
nnoremap <leader>gs :Gstatus<CR>
" aliases
:command! W w
" bind unused kes to map to them from outside
if &term =~ "screen"
  set  <F13>=[1;2P
  set  <F14>=[1;2Q
  set  <F15>=[1;2R
  set  <F16>=[1;2S
  set  <F17>=[1;5P
  set  <F18>=[1;5Q
  set  <F19>=[1;5R
  set  <F20>=[1;5A
  set  <F21>=[1;5B
elseif &term =~ "xterm"
  set  <F13>=O2P
  set  <F14>=O2Q
  set  <F15>=O2R
  set  <F16>=O2S
  set  <F17>=O5P
  set  <F18>=O5Q
  set  <F19>=O5R
  set  <F20>=[1;5A
  set  <F21>=[1;5B
endif

" " use some unused function key codes to
" " make special key combos work in terminal
map  <F13> <M-Up>
map  <F14> <M-Down>

" " }}}
" Abbreviations {{{
" html tag closing
iabbrev <// </<C-x><C-o>
iabbrev teh the
"}}}
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
" " }}}
" EasyMotion {{{
" Search with easy motion, also re-map n,N for search traversal to get
" different highlighting
map ? <Plug>(easymotion-sn)
omap ? <Plug>(easymotion-tn)
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
nmap s <Plug>(easymotion-s)
nmap S <Plug>(easymotion-s2)
" map leader hjkl to trigger easymotion moves
map <Leader>l <Plug>(easymotion-lineforward)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map <Leader>h <Plug>(easymotion-linebackward)

let g:EasyMotion_startofline = 0 " keep cursor colum when JK motion
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
  let g:syntastic_check_on_open=1
  let g:syntastic_always_populate_loc_list=1
  autocmd Filetype html set foldmethod=indent foldlevel=99
endif
" }}}
" Airline {{{
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
"let g:airline_theme='base16'
" }}}
" CtrlP {{{
let g:ctrlp_custom_ignore = {
            \ 'dir':  '\v[\/]\.(git|hg|svn)|node_modules$|bower_components$|build$|tmp$|packages$|node_modules$',
            \ 'file': '\v\.(exe|so|dll)$',
            \ 'link': 'some_bad_symbolic_links',
            \ }
let g:ctrlp_use_caching = 0
if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor

    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
else
  let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . -co --exclude-standard', 'find %s -type f']
  let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<space>', '<cr>', '<2-LeftMouse>'],
    \ }
endif
" }}}
" Syntastic {{{
let g:syntastic_disabled_filetypes=['go']
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_python_checkers = ['pep8']
" }}}
" Clang Format {{{
let g:clang_format#auto_formatexpr=1
"}}}
"{{{ Go Lang
let g:go_fmt_fail_silently = 1
let g:go_fmt_command = "goimports"
set runtimepath+=$GOROOT/misc/vim
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>b <Plug>(go-def)
au FileType go nmap <Leader>r <Plug>(go-referrers)
au FileType go nmap <F6> <Plug>(go-rename)
au FileType go vmap <F6> <Plug>(go-rename)
au FileType go imap <F6> <Plug>(go-rename)
" }}}
" Multiple cursors {{{
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'
" }}}
" " {{{ Completion
set complete=.,w,b,u,t,i,kspell
set completeopt=menu,longest
" "  }}}
" YMC you compelte me configuration {{{
let g:ycm_filetype_blacklist = { 'python': 0 }
let g:ycm_auto_trigger = 1
let g:ycm_add_preview_to_completeopt = 0
nmap <leader>b :YcmCompleter GoTo<CR>
vmap <leader>b :YcmCompleter GoTo<CR>

let g:ulti_expand_or_jump_res = 0
function! ExpandSnippetOrCarriageReturn()
    let snippet = UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res > 0
        return snippet
    else
        return "\<CR>"
    endif
endfunction
inoremap <expr> <CR> pumvisible() ? "<C-R>=ExpandSnippetOrCarriageReturn()<CR>" : "\<CR>"
"}}}
" Jedi {{{
let g:jedi#show_call_signatures = "0"
" }}}
" UltiSnips {{{
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
" }}}
" NetRW {{{
let g:netrw_list_hide = '\.o,\.obj,\.pyc'
" }}}
" NerdCommenter {{{
let g:NERDSpaceDelims=1
let g:NERDCustomDelimiters = { 'py' : { 'left': '# ', 'leftAlt': '', 'rightAlt': ''}}
" }}}
" Pencil {{{
let g:lexical#thesaurus = ['~/.vim/thesaurus/mthesaur.txt',]
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
                            \ | call lexical#init()
                            \ | call litecorrect#init()
                            \ | call textobj#quote#init()
                            \ | call textobj#sentence#init()
augroup END
" }}}
" yaml {{{
if has("autocmd")
  autocmd Filetype yaml set foldmethod=indent foldlevel=99
endif
" }}}
" podspec {{{
if has("autocmd")
  autocmd BufNewFile,BufRead Podfile,*.podspec set filetype=ruby
endif
" }}}
" Expand Region {{{
vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)

" Extend the global default
call expand_region#custom_text_objects({
      \ 'a]' :1,
      \ 'ab' :1,
      \ 'aB' :1,
      \ 'ii' :0,
      \ 'ai' :0,
      \ })

" }}}
" Vundle install {{{
if install_bundles == 1
    echo "Installing Bundles, please ignore key map error messages"
    echo ""
    :PluginInstall
endif
" }}}
