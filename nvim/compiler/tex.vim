if exists("current_compiler") | finish | endif
let current_compiler = "tex"

" ================================
" Compiler Command Setup
" ================================

" Define pdflatex and latexmk compile commands
let s:pdflatex = 'pdflatex -file-line-error -interaction=nonstopmode -halt-on-error -synctex=1 -output-directory=%:h %'
let s:latexmk  = 'latexmk -pdf -output-directory=%:h %'

" Flags for compilation options
let b:tex_use_latexmk = 0         " 0 = pdflatex, 1 = latexmk
let b:tex_use_shell_escape = 0    " 0 = no shell escape, 1 = enable shell escape

" ================================
" Shell Escape Auto-Detection
" ================================

" Automatically detect if 'minted' is used in the preamble and enable shell escape
silent execute '!sed "/\\begin{document}/q" ' . expand('%') . ' | grep "minted" > /dev/null'
if v:shell_error
  let b:tex_use_shell_escape = 0
else
  let b:tex_use_shell_escape = 1
endif

" ================================
" Toggle Functions
" ================================

" Toggle between pdflatex and latexmk
function! s:TexToggleLatexmk() abort
  let b:tex_use_latexmk = !b:tex_use_latexmk
  call s:TexSetMakePrg()
endfunction

" Toggle shell escape on/off
function! s:TexToggleShellEscape() abort
  let b:tex_use_shell_escape = !b:tex_use_shell_escape
  call s:TexSetMakePrg()
endfunction

" Set makeprg based on current settings
function! s:TexSetMakePrg() abort
  let l:shellescape = b:tex_use_shell_escape ? ' -shell-escape' : ''
  if b:tex_use_latexmk
    let &l:makeprg = 'latexmk -pdf' . l:shellescape . ' -output-directory=' . expand('%:h') . ' ' . expand('%')
  else
    let &l:makeprg = 'pdflatex -file-line-error -interaction=nonstopmode -halt-on-error -synctex=1' . l:shellescape . ' -output-directory=' . expand('%:h') . ' ' . expand('%')
  endif
endfunction

" Set makeprg initially
call s:TexSetMakePrg()

" ================================
" Key Mappings
" ================================

" Use <leader>m to run :Make (compile)
" noremap <leader>m <Cmd>Make<CR>

" Toggle latexmk compiler with <leader>tl
nmap <leader>tl <Plug>TexToggleLatexmk
nnoremap <script> <Plug>TexToggleLatexmk <SID>TexToggleLatexmk
nnoremap <SID>TexToggleLatexmk :call <SID>TexToggleLatexmk()<CR>

" Toggle shell escape with <leader>te
nmap <leader>te <Plug>TexToggleShellEscape
nnoremap <script> <Plug>TexToggleShellEscape <SID>TexToggleShellEscape
nnoremap <SID>TexToggleShellEscape :call <SID>TexToggleShellEscape()<CR>

" ================================
" Errorformat Configuration
" ================================

" Matches file name in error output
setlocal errorformat=%-P**%f
setlocal errorformat+=%-P**\"%f\"

" Match LaTeX errors
setlocal errorformat+=%E!\ LaTeX\ %trror:\ %m
setlocal errorformat+=%E%f:%l:\ %m
setlocal errorformat+=%E!\ %m

" Info for undefined control sequences
setlocal errorformat+=%Z<argument>\ %m

" Info for common LaTeX errors
setlocal errorformat+=%Cl.%l\ %m

" Ignore unmatched lines
setlocal errorformat+=%-G%.%#

