if exists("g:autoloaded_girlfriend") | finish | endif

let g:autoloaded_girlfriend = 1

let s:known_scopes = ['cursor', 'line', 'function', 'file']

" The 'main' process. Iterate over potential file
" candidates (cfile, mathces on line, etc.) and
" attempt to open them
function! girlfriend#do(cmd) abort
  let b:current_pos = getpos('.')
  let cmd = a:cmd
  let found = 0

  let found = girlfriend#runScope(cmd, { 'function': 'cursor' })

  " Try additional scopes, if any
  if !found && has_key(b:girlfriend_config, 'scopes')
    " Iterate over each scope in order
    for scope in b:girlfriend_config.scopes
      let found = girlfriend#runScope(cmd, scope)

      " Stop iterating scopes when we find a file
      if found
        break
      endif
    endfor
  endif

  " No match
  " TODO: Based on option, echo on no match
  if !found
    " If the cursor position was changed by any of the
    " scope runners, reset it
    if getpos('.') != b:current_pos
      call setpos('.', b:current_pos)
    endif
  endif
endfunction

" At this point, we have a file candidate. This
" function is responsible for coercing that candidate
" based on suffixesadd and includeexpr (which are
" not handled by :find, :sfind, and :tabfind, although
" path is) and trying each to see if there's a file.
function! girlfriend#open(cmd, file) abort
  let cmd = a:cmd
  let file = a:file

  if girlfriend#try(cmd, file)
    return 1
  else
    if girlfriend#iterateSuffixes(cmd, file)
      return 1
    elseif !empty(&l:includeexpr)
      let transform = substitute(&l:includeexpr, 'v:fname', "'" . file . "'", '')
      exec "let transformed =" transform
      return girlfriend#iterateSuffixes(cmd, transformed)
    else
      return 0
    endif
  endif
endfunction

" Handle a single, fully processed file. For each candidate, this
" will be called with each suffix to add, and then again with each
" suffix to add after transforming the file using includeexpr
function! girlfriend#try(cmd, file) abort
  try
    exec a:cmd a:file
    return 1
  catch *
    return 0
  endtry
endfunction

" Iterate over each suffix in suffiesadd and call try with it
function! girlfriend#iterateSuffixes(cmd, file) abort
  let cmd = a:cmd
  let file = a:file

  for suf in split(&l:suffixesadd, ',')
    let found = girlfriend#try(cmd, file . suf)

    if found
      return 1
    endif
  endfor

  return 0
endfunction

function! girlfriend#runScope(cmd, scope) abort
  let cmd = a:cmd
  let scope = a:scope

  " Allow skipping scopes for certain filetypes
  if girlfriend#skipFiletype(scope)
    return 0
  endif

  let fn = girlfriend#getExecutionFn(scope)

  " If we still didn't find a function, just skip this scope
  if empty(fn)
    " TODO: Based on option, echo on missing scope function
    return 0
  endif

  " Call the function with the scope. It should return a filename
  " or a list of filenames to try opening.
  let candidates = call(fn, [scope])
  
  if type(candidates) == type('')
    let candidates = [candidates]
  endif

  " Try to open each candidate
  for candidate in candidates
    let found = girlfriend#open(cmd, candidate)
    
    " Stop iterating candidates if we found one that worked
    if found
      return 1
    endif
  endfor

  return 0
endfunction

function! girlfriend#skipFiletype(scope) abort
  let scope = a:scope
  let filetypes = split(&ft, '\.') 

  if has_key(scope, 'ft_blacklist') && index(filetypes, scope.ft_blacklist) != -1
    return 1
  endif
  
  if has_key(scope, 'ft_whitelist') && index(filetypes, scope.ft_whitelist) == -1
    return 1
  endif

  return 0
endfunction

" Get the function to process a scope
function! girlfriend#getExecutionFn(scope) abort
  let scope = a:scope

  " If scope.function exists, it's either a known scope,
  " like line or function or a previously registered scope
  " or a literal function to call. If it doesn't exist,
  " default to using the line scope.
  if has_key(scope, 'function')
    if index(s:known_scopes, scope.function) > -1
      return 'girlfriend#scope#' . scope.function
    endif

    let registered = girlfriend#register#getScope(scope.function)

    if !empty(registered)
      return registered
    else
      return scope.function
    endif
  else
    return 'girlfriend#scope#line'
  endif
endfunction


function! s:system(cmd) abort
  return split(system(a:cmd), '\n')[0]
endfunction

" function! s:callNode() abort
"   return s:system('node -e "console.log(require.resolve(''' . expand("<cword>") . '''))"')
" endfunction
