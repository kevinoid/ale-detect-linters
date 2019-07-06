if exists('g:loaded_ale_detect_javascript')
    finish
endif

let g:loaded_ale_detect_javascript = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Gets a list of names of linters which are likely to apply to the javascript
" file in a given buffer, based on its contents and path.
function! ale#detect#javascript#detectAll(buffer) abort
    let l:javascript_linters = []

    let l:save_suffixesadd = &suffixesadd
    let &suffixesadd = ''

    " Load nearest package.json, which is relevant to several linters
    let l:bufpath = expand('#' . a:buffer . ':p:h') . ';'
    let l:package_json =
    \   join(ale#detect#_utils#tryFindAndRead('package.json', l:bufpath), '')

    if stridx(l:package_json, '"eslint":') != -1
    \ || stridx(l:package_json, '"eslintConfig":') != -1
    \ || search('\m/[*/]\s*eslint-', 'cnw')
        call add(l:javascript_linters, 'eslint')
    else
        let &suffixesadd = '.js,.yaml,.yml,.json'
        let l:eslintrc = findfile('.eslintrc', l:bufpath)

        " Ignore "personal configuration" ~/.eslintrc which is not indicative
        if eslintrc isnot# ''
        \ && fnamemodify(l:eslintrc, ':~:r') isnot# '~/.eslintrc'
            call add(l:javascript_linters, 'eslint')
        endif

        let &suffixesadd = ''
    endif

    if stridx(l:package_json, '"flow-bin":') != -1
    \ || stridx(l:package_json, '"babel-preset-flow":') != -1
        call add(l:javascript_linters, 'flow')
    endif

    if stridx(l:package_json, '"jscsConfig":') != -1
    \ || findfile('.jscsrc', l:bufpath) isnot# ''
    \ || findfile('.jscs.json', l:bufpath) isnot# ''
    \ || findfile('.jscs.yaml', l:bufpath) isnot# ''
        let b:ale_linters = ['jscs']
    endif

    if stridx(l:package_json, '"jshintConfig":') != -1
    \ || search('\m/\*\s*jshint\>', 'cnw')
    \ || findfile('.jshintrc', l:bufpath) isnot# ''
        call add(l:javascript_linters, 'jshint')
    endif

    if stridx(l:package_json, '"standard":') != -1
        call add(l:javascript_linters, 'standard')
    endif

    if stridx(l:package_json, '"xo":') != -1
        call add(l:javascript_linters, 'xo')
    endif

    let &suffixesadd = l:save_suffixesadd

    return l:javascript_linters
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
