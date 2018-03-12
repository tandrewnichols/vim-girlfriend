if exists('g:loaded_girlfriend') || &cp | finish | endif

let g:loaded_girlfriend = 1

if !exists('g:girlfriend')
  let g:girlfriend = {}
endif

let g:girlfriend = extend(g:girlfriend, {
  \ }, 'keep')

" let g:girlfriend_default_view = get(g:, "girlfriend_default_view", "edit")
" let g:girlfriend_create_missing_files = get(g:, "girlfriend_create_missing_files", 1)
" let g:girlfriend_create_mappings = get(g:, "girlfriend_create_mappings", 1)
"
" nnoremap <Plug>girlfriendDefault :call girlfriend#run('')<CR>
" nnoremap <Plug>girlfriendEdit :call girlfriend#run(':find')<CR>
" nnoremap <Plug>girlfriendSplit :call girlfriend#run(':sfind')<CR>
" nnoremap <Plug>girlfriendVsplit :call girlfriend#run(':vert sfind')<CR>
" nnoremap <Plug>girlfriendTabe :call girlfriend#run(':tabfind')<CR>
