if exists('g:loaded_ale_detect_typescript')
    finish
endif

let g:loaded_ale_detect_typescript = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Gets a list of names of linters which are likely to apply to the typescript
" file in a given buffer, based on its contents and path.
function! ale#detect#typescript#detectAll(buffer) abort
    let l:typescript_linters = []

    let l:save_suffixesadd = &suffixesadd
    let &suffixesadd = ''

    " Load nearest package.json, which is relevant to several linters
    let l:bufpath = expand('#' . a:buffer . ':p:h') . ';'
    let l:package_json =
    \   join(ale#detect#_utils#tryFindAndRead('package.json', l:bufpath), '')

    if stridx(l:package_json, '"typescript-eslint-parser":') != -1
    \ || stridx(l:package_json, '"@typescript-eslint/parser":') != -1
    \ || search('\m/[*/]\s*eslint-', 'cnw')
        call add(l:typescript_linters, 'eslint')
    else
        let &suffixesadd = '.js,.yaml,.yml,.json'

        for line in ale#detect#_utils#tryFindAndRead('.eslintrc', l:bufpath)
            if stridx(line, '"typescript"') != -1
                call add(l:typescript_linters, 'eslint')
                break
            endif
        endfor

        let &suffixesadd = ''
    endif

    if stridx(l:package_json, '"tslintConfig":') != -1
    \ || stridx(l:package_json, '"tslint":') != -1
    \ || findfile('tslint.json', l:bufpath) isnot# ''
    \ || findfile('tslint.yaml', l:bufpath) isnot# ''
        call add(l:typescript_linters, 'tslint')
    endif

    " tsserver is always applicable
    call add(l:typescript_linters, 'tsserver')

    " typecheck is always applicable
    call add(l:typescript_linters, 'typecheck')

    let &suffixesadd = l:save_suffixesadd

    return l:typescript_linters
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
