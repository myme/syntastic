"============================================================================
"File:        vimpython3.vim
"Description: Syntax checking plugin for syntastic.vim
"Maintainer:  LCD 47 <lcd047 at gmail dot com>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================

if exists("g:loaded_syntastic_python_vimpython3_checker")
    finish
endif
let g:loaded_syntastic_python_vimpython3_checker = 1

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_python_vimpython3_IsAvailable() dict " {{{1
    if has('python3')
        python import vim
        return 1
    endif
    return 0
endfunction " }}}1

function! SyntaxCheckers_python_vimpython3_GetLocList() dict " {{{1
    let loclist = []

    python3 <<EOT
buf = vim.current.buffer
loclist = vim.bindeval("loclist")

try:
    compile("\n".join(buf), buf.name, "exec", 0, 1)
except SyntaxError as err:
    loclist.extend([{
        "bufnr": buf.number,
        "lnum": err.lineno,
        "col": err.offset,
        "vcol": 0,
        "type": "E",
        "text": err.msg,
        "valid": 1 }])
EOT

    return loclist
endfunction " }}}1

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'python',
    \ 'name': 'vimpython3',
    \ 'exec': ''})

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
