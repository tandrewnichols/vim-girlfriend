function! girlfriend#scope#cursor(scope)
  return [expand("<cfile>"), expand("<cword>")]
endfunction

function! girlfriend#scope#line(scope) abort
  let scope = a:scope

  let patterns = type(scope.pattern) == type('') ? [ scope.pattern ] : scope.pattern
  let line = getline('.')
  let files = []

  for pattern in patterns
    let maybefile = matchstr(line, pattern)
    if !empty(maybefile)
      call add(files, maybefile)
    endif
  endfor

  return files
endfunction

function! girlfriend#scope#grep(scope) abort
  let scope = a:scope

  let cfile = expand("<cfile>")
  let cword = expand("<cword>")

  let where = globpath(scope.where . '/**')
  " let transform
endfunction
