" Throw girlfriend-specific errors
function! girlfriend#throw(fn, name, msg) abort
  let v:errmsg = 'girlfriend#' . a:fn . ' - ' . a:name . ': ' . a:msg
  throw v:errmsg
endfunction

" If the item passed in is not a List, make it a List
function! girlfriend#ensureList(stringOrList) abort
  return type(a:stringOrList) == 3 ? a:stringOrList : [ a:stringOrList ]
endfunction

" Register strategies for particular locations
function! girlfriend#register(name, locations, config) abort
  if type(a:config) != 4
    call girlfriend#throw('register', a:name, 'config must be a Dict')
  endif

  let locations = girlfriend#ensureList(a:locations)
  let config = a:config

  if len(locations)
    call map(locations, "v:val !~ '^\*[\/\.]' ? '*/' . v:val : v:val")
  else
    let locations = ['*.*']
  endif
  let aupat = join(locations, ',')

  augroup girlfriend-patterns
    au!
    exec "au BufEnter" aupat "call girlfriend#apply(config)"
  augroup END
endfunction

" Set local/buffer settings for gf and friends
function! girlfriend#apply(config) abort
  let config = a:config

  if has_key(config, 'path')
    call girlfriend#setPath(config.path)
  endif

  if has_key(config, 'ext')
    call girlfriend#setExt(config.ext)
  endif

  if !exists("b:girlfriend_strategies")
    let b:girlfriend_strategies = []
  endif

  let strategies = girlfriend#ensureList(config.strategies)
  let b:girlfriend_strategies += girlfriend#createStrategies(strategies)
endfunction

function! girlfriend#setPath(paths) abort
  let git = finddir('.git', './;')
  let root = git == '.git' ? getcwd() : fnamemodify(git, ':h')
  let paths = girlfriend#ensureList(copy(a:paths))
  call map(paths, "root . '/' . v:val")
  exec "setlocal path+=," . join(paths, ',')
endfunction

function! girlfriend#setExt(ext) abort
  let exts = girlfriend#ensureList(a:ext)
  exec "setlocal suffixesadd+=," . join(exts, ',')
endfunction

function! girlfriend#createStrategies(strategies) abort
  let strategies = []
  for strategy in a:strategies
    let scopes = has_key(strategy, 'scope') ? split(strategy.scope, '|') : ['cursor', 'line', 'def']
    if len(scopes) == 1
      let strategies += strategy
    else
      call map(scopes, "extend(deepcopy(strategy), { 'scope': v:val })")
      let strategies += scopes
    endif
  endfor

  return strategies
endfunction

" When gf is pressed, iterate over strategies
function! girlfriend#run(view) abort
  let b:current_pos = getcurpos()
  let found = 0
  let view = girlfriend#getView(a:view)

  " No view was passed in and no default was set. Just do the normal thing.
  if empty(view)
    return girlfriend#bail()
  endif

  let found = girlfriend#load(view, "\<cfile>")
  if !found
    " If we couldn't find the file under the cursor and there are no buffer-local
    " strategies to try, call through to the normal functionality.
    if !exists("b:girlfriend_strategies") || empty(b:girlfriend_strategies)
      return girlfriend#bail()
    endif

    call sort(b:girlfriend_strategies, function("girlfriend#sortStrategies"))
    for l:Strategy in b:girlfriend_strategies
      " type 2 = Funcref
      let file = type(l:Strategy) == 2 ? l:Strategy() : girlfriend#handleStrategy(l:Strategy)
      let found = girlfriend#load(view, file)
      call girlfriend#reset()
      if found
        break
      endif
    endfor
  endif

  if !found
    call setpos('.', b:current_pos)
  endif
  unlet b:current_pos
endfunction

function! girlfriend#handleStrategy(strategy) abort
  let scope = has_key(a:strategy, 'scope') ? a:strategy.scope : 'cursor|line|def'
  let scopes = split(scope, '|')
  if has_key(a:strategy, 'path')
    let b:existing_path = &path
    call girlfriend#setPath(a:strategy.path)
  endif
  if has_key(a:strategy, 'ext')
    let b:existing_ext = &suffixesadd
    call girlfriend#setExt(a:strategy.ext)
  endif
  exec "return  girlfriend#strategies#" . a:strategy.type . "#" . a:strategy.scope . "(l:Strategy)"
endfunction

function! girlfriend#reset() abort
  if exists("b:existing_path")
    exec "setlocal path=" . b:existing_path
    unlet b:existing_path
  endif

  if exists("b:existing_ext")
    exec "setlocal suffixesadd=" . b:existing_ext
    unlet b:existing_ext
  endif
endfunction

function! girlfriend#bail() abort
  normal! gf
  return
endfunction

" Try loading a file, but ignore the error
function! girlfriend#load(view, file) abort
  if empty(a:file)
    return 0
  endif

  try
    exec a:view a:file
    return 1
  catch
    return 0
  endtry
endfunction

" Figure out what view to load the file in
let s:girlfriend_default_views = {
      \   "edit": ":find",
      \   "split": ":sfind",
      \   "vsplit": ":vert sfind",
      \   "tabe": ":tabfind"
      \ }
function! girlfriend#getView(view) abort
  return empty(a:view) ? get(s:girlfriend_default_views, g:girlfriend_default_view, "") : a:view
endfunction

function! girlfriend#sortStrategies(first, second) abort
  " Put all custom functions at the end of the list
  if type(a:first) == 2 && type(a:second) == 2
    return 0
  elseif type(a:first) == 2
    return 1
  elseif type(a:second) == 2
    return -1
  endif

  " If they're the same, sort them equally
  if a:first.scope == a:second.scope
    return 0
  endif

  " If either scope is 'cursor', prioritize that strategy,
  " but prefer the first item, in case the order they were
  " passed in matters.
  if a:first.scope == 'cursor'
    return -1
  elseif a:second.scope == 'cursor'
    return 1
  endif

  " If neither is cursor, the next highest priority is 'line,'
  " again prefering the first to the second.
  if a:first.scope == 'line'
    return -1
  elseif a:second.scope == 'line'
    return 1
  endif

  " If neither is 'line,' try again with 'file'
  if a:first.scope == 'file'
    return -1
  elseif a:second.scope == 'file'
    return 1
  endif

  " Just in case, keep the original order
  return -1
endfunction
