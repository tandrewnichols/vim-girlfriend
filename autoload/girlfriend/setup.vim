function! girlfriend#setup#initialize(config) abort
  let config = a:config
  let b:girlfriend_config = config

  call girlfriend#setup#options(config)

  nnoremap <buffer> gf :call girlfriend#do('find')<CR>
  nnoremap <buffer> <C-g>s :call girlfriend#do('sfind')<CR>
  nnoremap <buffer> <C-g>v :call girlfriend#do('vert sfind')<CR>
  nnoremap <buffer> <C-g>t :call girlfriend#do('tabfind')<CR>
endfunction

function! girlfriend#setup#options(config) abort
  let config = a:config
  if has_key(config, 'suffixesadd')
    if type(config.suffixesadd) == type('')
      let config.suffixesadd = split(config.suffixesadd, ',')
    endif
    let suffixesadd = map(config.suffixesadd, 'stridx(v:val, ".") == 0 ? v:val : "." . v:val')
    exec "setlocal suffixesadd=" . join(suffixesadd, ',')
  endif

  if has_key(config, 'path')
    if type(config.path) == type('')
      let config.path = split(config.path, ',')
    endif
    let path = map(config.path, 'stridx(v:val, ''/'') == 0 ? v:val : projectroot#guess() . "/" . v:val')
    exec "setlocal path+=," . join(path, ',')
  endif

  if has_key(config, 'includeexpr')
    if type(config.includeexpr) == type([])
      let includeexpr = "substitute(v:fname, '" . config.includeexpr[0] . "', '" . config.includeexpr[1] . "')"
    else
      let includeexpr = config.includeexpr
    endif

    exec "let &l:includeexpr=includeexpr"
  endif
endfunction
