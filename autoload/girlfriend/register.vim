if exists("g:autoloaded_girlfriend_register") | finish | endif

let g:autoloaded_girlfriend_register = 1

let s:scopes = {}

augroup GirlfriendSetup
  au!
augroup END

function! girlfriend#register#directory(directory, opts) abort
  for entry in items(a:opts)
    exec "au GirlfriendSetup BufEnter */" . a:directory . "/" . entry[0] . " call girlfriend#setup#initialize(" . string(entry[1]) . ")"
  endfor
endfunction

function! girlfriend#register#filetypes(types, opts) abort
  let types = a:types
  if type(types) == type('')
    types = [types]
  endif

  exec "au GirlfriendSetup Filetype" join(types, ',') "call girlfriend#setup#initialize(" . string(a:opts) . ")"
endfunction

function! girlfriend#register#scope(name, fn) abort
  let s:scopes[ a:name ] = a:fn
endfunction

function! girlfriend#register#getScope(name) abort
  return has_key(s:scopes, a:name) ? s:scopes[ a:name ] : 0
endfunction
