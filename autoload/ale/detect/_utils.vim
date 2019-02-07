if exists('g:loaded_ale_detect__utils')
    finish
endif

let g:loaded_ale_detect__utils = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Find a file and try to read its contents.
function! ale#detect#_utils#tryFindAndRead(...) abort
    let l:found = call('findfile', a:000)

    if l:found isnot# ''
        try
            return readfile(l:found)
        catch /^E484:/
            " File is not readable.  Fall through.
        endtry
    endif

    return []
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
