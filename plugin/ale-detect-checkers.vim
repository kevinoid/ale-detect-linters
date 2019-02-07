" Checker detection for ALE
" Maintainer:   Kevin Locke <kevin@kevinlocke.name>
" Repository:   https://github.com/kevinoid/ale-detect-linters
" License:      2-Clause BSD
" Last Change:  1 February 2019

if exists('g:loaded_ale_detect_linters')
    finish
endif

let g:loaded_ale_detect_linters = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

if get(g:, 'ale_detect_linters', 1)
    augroup aleDetectLinters
        autocmd!

        autocmd FileType javascript let b:ale_linters =
            \ ale#detect#javascript#detectAll()
        autocmd FileType python let b:ale_linters =
            \ ale#detect#python#detectAll()
        autocmd FileType typescript let b:ale_linters =
            \ ale#detect#typescript#detectAll()
    augroup END
endif

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
