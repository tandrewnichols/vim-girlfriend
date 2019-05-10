function! girlfriend#strategies#match#cursor(config) abort
  return girlfriend#helpers#getMatchAtCursor(a:config.pattern)
endfunction

function! girlfriend#strategies#match#line(config) abort
  return girlfriend#helpers#extractMatch(a:config.pattern)
endfunction

function! girlfriend#strategies#match#def(config) abort
  let [variable, fn] = girlfriend#helpers#getVariableUnderCursor()
  let defPattern = girlfriend#helpers#getDefinitionPattern()
  call cursor(0, 0)
  let matchcol = search(substitute(defPattern, '${variable}', variable, ''), 'c')
  if matchcol
    return [ expand("<cfile>"), fn ]
  endif
endfunction
