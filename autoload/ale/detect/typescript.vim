if exists('g:loaded_ale_detect_typescript')
    finish
endif

let g:loaded_ale_detect_typescript = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Gets a list of names of linters which are likely to apply to the typescript
" file in the current buffer, based on its contents and path.
function! ale#detect#typescript#detectAll() abort
    let typescript_linters = []

    let save_suffixesadd = &suffixesadd
    let &suffixesadd = ''

    " Load nearest package.json, which is relevant to several linters
    let package_json = findfile('package.json', '.;')

    if package_json isnot# ''
        let package_json = join(readfile(package_json))
    endif

    if stridx(package_json, '"typescript-eslint-parser":') != -1
        \ || stridx(package_json, '"@typescript-eslint/parser":') != -1
        \ || search('\m/[*/]\s*eslint-', 'cnw')
        call add(typescript_linters, 'eslint')
    else
        let &suffixesadd = '.js,.yaml,.yml,.json'
        let eslintrc = findfile('.eslintrc', '.;')

        if eslintrc isnot# ''
            for line in readfile(eslintrc)
                if stridx(line, '"typescript"') != -1
                    call add(typescript_linters, 'eslint')
                    break
                endif
            endfor
        endif

        let &suffixesadd = ''
    endif

    if stridx(package_json, '"tslintConfig":') != -1
        \ || stridx(package_json, '"tslint":') != -1
        \ || findfile('tslint.json', '.;') isnot# ''
        \ || findfile('tslint.yaml', '.;') isnot# ''
        call add(typescript_linters, 'tslint')
    endif

    " tsserver is always applicable
    call add(typescript_linters, 'tsserver')

    " typecheck is always applicable
    call add(typescript_linters, 'typecheck')

    let &suffixesadd = save_suffixesadd

    return typescript_linters
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
