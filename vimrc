set nocompatible
set textwidth=78
set tabstop=4
set shiftwidth=4
set noexpandtab
set smarttab
set smartindent
set autoindent
set ruler
set number
set hlsearch
set incsearch
set visualbell
set showmatch
set matchtime=3
set smartcase
set ignorecase
set backspace=2
imap <S-Del> <Del>
set enc=utf-8
set fenc=utf=8
set termencoding=utf-8
set formatoptions=qlcor
"set viminfo='2000,fl,\"500
syntax on


" GUI Stuff
set guioptions-=m
set guioptions-=T
set guioptions-=r
set guioptions-=L
"set mouse=a
set background=dark
set guifont=Courier\ New:h9
set guifontwide=Courier\ New:h9
highlight Visual term=reverse cterm=reverse gui=reverse guifg=Grey guibg=Black
highlight Normal guibg=black guifg=lightgrey

" Plugins
filetype plugin on

" Remember last position
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
endif
