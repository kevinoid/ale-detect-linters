if exists('g:loaded_ale_detect_javascript')
    finish
endif

let g:loaded_ale_detect_javascript = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Gets a list of names of linters which are likely to apply to the javascript
" file in the current buffer, based on its contents and path.
function! ale#detect#javascript#detectAll() abort
    let javascript_linters = []

    let save_suffixesadd = &suffixesadd
    let &suffixesadd = ''

    " Load nearest package.json, which is relevant to several linters
    let package_json = findfile('package.json', '.;')

    if package_json isnot# ''
        let package_json = join(readfile(package_json))
    endif

    if stridx(package_json, '"eslint":') != -1
        \ || stridx(package_json, '"eslintConfig":') != -1
        \ || search('\m/[*/]\s*eslint-', 'cnw')
        call add(javascript_linters, 'eslint')
    else
        let &suffixesadd = '.js,.yaml,.yml,.json'

        if findfile('.eslintrc', '.;') isnot# ''
            call add(javascript_linters, 'eslint')
        endif

        let &suffixesadd = ''
    endif

    if stridx(package_json, '"flow-bin":') != -1
        \ || stridx(package_json, '"babel-preset-flow":') != -1
        call add(javascript_linters, 'flow')
    endif

    if stridx(package_json, '"jscsConfig":') != -1
        \ || findfile('.jscsrc', '.;') isnot# ''
        \ || findfile('.jscs.json', '.;') isnot# ''
        \ || findfile('.jscs.yaml', '.;') isnot# ''
        let b:ale_linters = ['jscs']
    endif

    if stridx(package_json, '"jshintConfig":') != -1
        \ || search('\m/\*\s*jshint\>', 'cnw')
        \ || findfile('.jshintrc', '.;') isnot# ''
        call add(javascript_linters, 'jshint')
    endif

    if stridx(package_json, '"standard":') != -1
        call add(javascript_linters, 'standard')
    endif

    if stridx(package_json, '"xo":') != -1
        call add(javascript_linters, 'xo')
    endif

    let &suffixesadd = save_suffixesadd

    return javascript_linters
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
