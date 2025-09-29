" -------------------- Plugins --------------------
call plug#begin()
" LuaSnip Plugin
Plug 'https://github.com/L3MON4D3/LuaSnip.git'
" VimTeX for LaTeX editing
Plug 'lervag/vimtex'
Plug 'micangl/cmp-vimtex'
" Onedark color scheme
Plug 'navarasu/onedark.nvim'
" UltiSnips for snippets
Plug 'https://github.com/SirVer/ultisnips.git'
" Vim-dispatch for async compilation
Plug 'https://github.com/tpope/vim-dispatch.git'
" Completion Plugins
Plug 'hrsh7th/nvim-cmp'           " Completion engine
Plug 'hrsh7th/cmp-buffer'         " Buffer completions
Plug 'hrsh7th/cmp-path'           " Path completions
Plug 'hrsh7th/cmp-nvim-lsp'       " LSP source for nvim-cmp
Plug 'hrsh7th/cmp-vsnip'          " Snippet support
Plug 'hrsh7th/vim-vsnip'          " Snippet engine
Plug 'neovim/nvim-lspconfig'	  " Texlab support
" Github copilot
Plug 'https://github.com/github/copilot.vim.git'
call plug#end()

" -------------------- Colorscheme --------------------
let g:onedark_config = {
    \ 'style': 'deep',
\}
colorscheme onedark

" -------------------- Python3 Config --------------------
let g:python3_host_prog = expand('~/.venvs/nvim/bin/python')

" -------------------- Editor Defaults --------------------
set number
set tabstop=4
set shiftwidth=4
set nofoldenable
set encoding=utf-8

set splitbelow
set splitright
set autoindent
set smartindent

" -------------------- UltiSnips --------------------
let g:UltiSnipsExpandTrigger       = '<C-l>'
let g:UltiSnipsJumpForwardTrigger  = '<C-l>'
let g:UltiSnipsJumpBackwardTrigger = '<C-h>'
let g:UltiSnipsSnippetDirectories = ['UltiSnips']

" -------------------- Verilog Configuration --------------------
autocmd BufNewFile,BufRead *.v,*.sv set filetype=verilog
" Use 4 spaces for indentation in Verilog files
autocmd FileType verilog setlocal shiftwidth=4 tabstop=4 expandtab

" -------------------- VimTeX Configuration --------------------
filetype plugin on
filetype indent on
syntax enable

let g:vimtex_view_method = 'zathura'
let maplocalleader = ","

" Automatically open Zathura after first successful compile
let g:vimtex_view_automatic = 0
augroup vimtex_event_view
  autocmd!
  autocmd User VimtexEventCompileSuccess VimtexView
augroup END

let g:vimtex_quickfix_ignore_filters = [
      \ 'Underfull \\hbox',
      \ 'Overfull \\hbox',
      \ 'LaTeX Warning: .\+ float specifier changed to',
      \ 'LaTeX hooks Warning',
      \ 'Package siunitx Warning: Detected the "physics" package:',
      \ 'Package hyperref Warning: Token not allowed in a PDF string',
      \]

function! s:SaveDetectMintedAndMake()
  " Save the current buffer
  write

  " Check only until \begin{document} for 'minted'
  silent execute '!sed "/\\begin{document}/q" ' . shellescape(expand('%:p')) . ' | grep "minted" > /dev/null'

  if v:shell_error
    let b:tex_use_shell_escape = 0
  else
    let b:tex_use_shell_escape = 1
  endif

  " Run :Make
  Make
endfunction

autocmd FileType tex compiler tex

"--------------------- Vimtex Autocomplete ------------
lua << EOF
local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For vsnip users.
    end,
  },
  mapping = {
    ['<A-k>'] = cmp.mapping.select_next_item(),
    ['<A-j>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<A-Space>'] = cmp.mapping.complete(),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
	{ name = 'vimtex' },
    { name = 'buffer' },
    { name = 'path' }
  })
})
EOF

lua << EOF
vim.lsp.start({
  name = "texlab",
  cmd = { "texlab" },
  root_dir = vim.fs.dirname(vim.fs.find({".git", "*.tex"}, { upward = true })[1]),
})
EOF

let g:vimtex_complete_enabled = 1
let g:vimtex_env_change_autofill = 1
let g:vimtex_imaps_enabled = 1

" ----------- Search Commands ------------------------
set ignorecase				" Lowercase = uppercase during search
set smartcase				" Capitals important only if included
set inccommand=split " To see changes as they're madke

" -------------------- Completions --------------------
inoremap <expr> <A-j> pumvisible() ? "\<C-n>" : "\<A-j>"
inoremap <expr> <A-h> pumvisible() ? "\<C-p>" : "\<A-h>"

" ----------------- Key Mappings Tex -----------------
nmap <leader>v <plug>(vimtex-view)
nmap <leader>c <plug>(vimtex-clean)
noremap <leader>m <Cmd>Make<CR>
nnoremap <silent> <Esc> :noh<CR><ESC>
noremap <leader>m :call <SID>SaveDetectMintedAndMake()<CR>

" -------------------- Terminal Commands --------------------
" Horizontal split terminal
command! Hterm split <bar> terminal

" Vertical split terminal
command! Vterm vsplit <bar> terminal


" -------------------- Key Mappings Arduino-------------------
" Function to select board and return Port + FQBN
function! ArduinoSelectBoard()
  let l:boards = split(system('arduino-cli board list'), "\n")
  if len(l:boards) < 2
    echo "No boards detected!"
    return ""
  endif

  " Remove header line
  call remove(l:boards, 0)

  " Show numbered list for selection
  let l:choices = []
  for l:line in l:boards
    call add(l:choices, l:line)
  endfor

  let l:choice = inputlist(['Select board:'] + l:choices)
  if l:choice < 1 || l:choice > len(l:boards)
    echo "Invalid selection!"
    return ""
  endif

  " Split the chosen line
  let l:selected = split(l:boards[l:choice - 1])

  " Port is the first column
  let l:port = l:selected[0]

  " FQBN is second-to-last column ([-2]) instead of last
  let l:fqbn = l:selected[-2]

  return l:port . " " . l:fqbn
endfunction

" Compile mapping
nnoremap <leader>ac :w <CR> :call ArduinoCompile()<CR>

" Upload mapping
nnoremap <leader>au :call ArduinoUpload()<CR>

" Compile function
function! ArduinoCompile()
  let l:data = ArduinoSelectBoard()
  if empty(l:data) | return | endif
  let [l:port, l:fqbn] = split(l:data)
  execute '!arduino-cli compile --fqbn ' . shellescape(l:fqbn) . ' ' . shellescape(expand('%:p:h'))
endfunction

" Upload function
function! ArduinoUpload()
  let l:data = ArduinoSelectBoard()
  if empty(l:data) | return | endif
  let [l:port, l:fqbn] = split(l:data)
  execute '!arduino-cli upload -p ' . shellescape(l:port) . ' --fqbn ' . shellescape(l:fqbn) . ' ' . shellescape(expand('%:p:h'))
endfunction

