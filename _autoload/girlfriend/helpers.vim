let s:definition_patterns = {
      \   'js': [
      \     '\(var\|const\|let\)\?\s\?${variable}\s\?=\s\?require(["'']\zs[^"'']\+\ze["''])',
      \     'import\s${variable}\sfrom\s["'']\zs[^"'']\+\ze["'']'
      \   ],
      \   'coffee': ['${variable}\s\?=\s\?require[(\s]["'']\zs[^"'']\+\ze["''][)\s]']
      \ }
let s:object_separators = {
      \   'perl': '->'
      \ }

let s:definition_patterns.jsx = s:definition_patterns.js

function! girlfriend#helpers#getMatchAtCursor(pattern) abort
  let cursorcol = getcurpos()[2]
  let line = getline('.')
  let matchpos = matchstrpos(line, a:pattern)
  if matchpos[1] > -1 && matchpos[1] < cursorcol && matchpos[2] > cursorcol
    return girlfriend#helpers#extractMatch(a:pattern)
  endif
endfunction

function! girlfriend#helpers#extractMatch(pattern) abort
  let matches = matchlist(getline('.'), a:pattern)
  return get(matches, 1)
endfunction

function! girlfriend#helpers#getDefinitionPattern() abort
  for ft in split(&filetype, '.')
    if exists("g:girlfriend_" . ft . "_definition_pattern")
      exec "return g:girlfriend_" . ft . "_definition_pattern"
    elseif has_key(s:definition_patterns, ft)
      return s:definition_patterns[ ft ]
    endif
  endfor
endfunction

function! girlfriend#helpers#getSeparator() abort
  for ft in split(&filetype, '.')
    if exists("g:girlfriend_" .ft . "_object_separator")
      exec "return g:girlfriend_" .ft . "_object_separator"
    elseif has_key(s:object_separators, ft)
      return s:object_separators[ ft ]
    else
      return "\."
    endif
  endfor
endfunction

function! girlfriend#helpers#getVariableUnderCursor() abort
  let cword = expand("<cword>")
  let curIsk = &iskeyword
  let separator = girlfriend#helpers#getSeparator()
  exec "setlocal iskeyword+=" . join(split(separator, ''), ',')
  let jsword = split(expand("<cword>"), separator)
  let &iskeyword = curIsk

  if cword == jsword[0]
    return [ cword, '' ]
  else
    return [ jsword[0], cword ]
  endif
endfunction
