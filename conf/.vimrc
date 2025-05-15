set hlsearch
set incsearch
set ignorecase
set smartcase
set showmode
set number
set relativenumber
set scrolloff=3
set history=500
set clipboard=unnamedplus,unnamed
set autowrite
set autoread
set vb
set updatetime=100
set wildmenu
set ts=4
set expandtab
set autoindent
set smartindent
set shiftwidth=4
set cursorline
nnoremap <Space>sc :nohlsearch<CR>
inoremap jj <Esc>
inoremap jk <Esc>
nnoremap H ^
nnoremap L $
nnoremap U <C-r>
vnoremap v <Esc>
map Q :q!<CR>
map W :w<CR>
exec "nohlsearch"
