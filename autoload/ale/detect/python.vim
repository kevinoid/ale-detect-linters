if exists('g:loaded_ale_detect_python')
    finish
endif

let g:loaded_ale_detect_python = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Gets a Dictionary of module names from requirements.txt, Pipfile, and
" pyproject.toml
function! s:LoadDependencies(buffer) abort
    let l:bufpath = expand('#' . a:buffer . ':p:h') . ';'

    let l:requirements_txt =
    \   ale#detect#_utils#tryFindAndRead('requirements.txt', l:bufpath)

    let l:requirements_dev_txt =
    \   ale#detect#_utils#tryFindAndRead('requirements-dev.txt', l:bufpath)

    if empty(l:requirements_dev_txt)
        let l:requirements_dev_txt =
        \   ale#detect#_utils#tryFindAndRead('dev-requirements.txt', l:bufpath)
    endif

    let l:requirements_test_txt =
    \   ale#detect#_utils#tryFindAndRead('requirements-test.txt', l:bufpath)

    if empty(l:requirements_test_txt)
        let l:requirements_test_txt =
        \   ale#detect#_utils#tryFindAndRead('test-requirements.txt', l:bufpath)
    endif

    let l:pipfile = []
    let l:in_packages = 0

    for l:line in ale#detect#_utils#tryFindAndRead('Pipfile', l:bufpath)
        if l:line =~# '\m\s*\[packages\]' || l:line =~# '\m\s*\[dev-packages\]'
            let l:in_packages = 1
        elseif l:line[0] =~# '\m\s*['
            let l:in_packages = 0
        elseif l:in_packages
            call add(l:pipfile, l:line)
        endif
    endfor

    let l:pyproject = []
    let l:in_deps = 0
    let l:in_groups = 0

    " FIXME: This is hacky and fragile.  Use or implement a TOML parser.
    for l:line in ale#detect#_utils#tryFindAndRead('pyproject.toml', l:bufpath)
        if l:line =~# '\m^\s*dependencies\s*='
            let l:in_deps = 1
        elseif l:line =~# '\m^\s*\[\s*project\s*\.\s*optional-dependencies\s*\]'
        \ || l:line =~# '\m^\s*\[\s*dependency-groups\s*\]'
            let l:in_groups = 1
            continue
        endif

        if l:in_groups || l:in_deps
            " Remove any comments
            let l:line = substitute(l:line, '#.*', '', '')
            " Remove group name
            let l:line = substitute(l:line, '^\s*\(''[^'']*''\|"[^"]*"\|\S*\)\s*=\s*\[', '', '')
            " Remove include-group
            let l:line = substitute(l:line, '{\s*[''"]\?include-group[''"]\?\s*=[^}]*}', '', '')
            " Add each single-quoted string to l:pyproject
            call substitute(l:line, '''\([^'']*\)''', '\=add(l:pyproject, submatch(1))', 'g')
            " Add each double-quoted string to l:pyproject
            call substitute(l:line, '"\([^"]*\)"', '\=add(l:pyproject, submatch(1))', 'g')

            " Check for end of dependencies array or group table
            if l:in_deps && stridx(l:line, ']')
                let l:in_deps = 0
            elseif l:in_groups && l:line =~# '\m^\s*\['
                let l:in_groups = 0
            endif
        endif
    endfor

    let l:dependencies = {}

    for l:line in l:requirements_txt
    \ + l:requirements_dev_txt
    \ + l:requirements_test_txt
    \ + l:pipfile
    \ + l:pyproject
        let l:line = trim(l:line)

        " Ignore blank lines, options, and comments
        if l:line[0] isnot# ''
        \ && l:line[0] isnot# '-'
        \ && l:line[0] isnot# '#'
            let l:parts = split(l:line, '\m[<>=!\s]\+')
            let l:package = l:parts[0]
            let l:dependencies[l:package] = 1
        endif
    endfor

    return l:dependencies
endfunction

" Gets a list of names of linters which are likely to apply to the python
" file in a given buffer, based on its contents and path.
function! ale#detect#python#detectAll(buffer) abort
    let l:python_linters = []

    let l:save_suffixesadd = &suffixesadd
    let &suffixesadd = ''

    " Load files which can be used by multiple linters
    let l:bufpath = expand('#' . a:buffer . ':p:h') . ';'
    let l:pyproject_toml =
    \ join(ale#detect#_utils#tryFindAndRead('pyproject.toml', l:bufpath), "\n")
    let l:pytest_ini =
    \ join(ale#detect#_utils#tryFindAndRead('pytest.ini', l:bufpath), "\n")
    let l:setup_cfg =
    \ join(ale#detect#_utils#tryFindAndRead('setup.cfg', l:bufpath), "\n")
    let l:tox_ini =
    \ join(ale#detect#_utils#tryFindAndRead('tox.ini', l:bufpath), "\n")

    let l:dependencies = s:LoadDependencies(a:buffer)

    if has_key(l:dependencies, 'bandit')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*bandit\s*[\].]'
    \ || findfile('.bandit', l:bufpath) isnot# ''
        call add(l:python_linters, 'bandit')
    endif

    if has_key(l:dependencies, 'flake8')
    \ || l:setup_cfg =~# '\v%(^|\n)\s*\[flake8\]'
    \ || l:tox_ini =~# '\v%(^|\n)\s*\[flake8\]'
    \ || search('\m#\s*flake8:', 'cnw')
    \ || findfile('.flake8', l:bufpath) isnot# ''
        call add(l:python_linters, 'flake8')
    endif

    if has_key(l:dependencies, 'mypy')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*mypy\s*\]'
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\[\s*tool\s*\.\s*mypy\s*\.'
    \ || l:setup_cfg =~# '\v%(^|\n)\s*\[mypy\]'
    \ || findfile('mypy.ini', l:bufpath) isnot# ''
    \ || findfile('.mypy.ini', l:bufpath) isnot# ''
        call add(l:python_linters, 'mypy')
    endif

    if has_key(l:dependencies, 'prospector')
    \ || finddir('.prospector', l:bufpath) isnot# ''
    \ || finddir('prospector', l:bufpath) isnot# ''
    \ || findfile('.landscape.yml', l:bufpath) isnot# ''
    \ || findfile('.landscape.yaml', l:bufpath) isnot# ''
    \ || findfile('landscape.yml', l:bufpath) isnot# ''
    \ || findfile('landscape.yaml', l:bufpath) isnot# ''
    \ || findfile('.prospector.yaml', l:bufpath) isnot# ''
    \ || findfile('.prospector.yml', l:bufpath) isnot# ''
    \ || findfile('prospector.yaml', l:bufpath) isnot# ''
    \ || findfile('prospector.yml', l:bufpath) isnot# ''
        call add(l:python_linters, 'prospector')
    endif

    if has_key(l:dependencies, 'pydocstyle')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*pydocstyle\s*\]'
    \ || l:setup_cfg =~# '\v%(^|\n)\s*\[pydocstyle\]'
    \ || l:setup_cfg =~# '\v%(^|\n)\s*\[pep257\]'
    \ || l:tox_ini =~# '\v%(^|\n)\s*\[pydocstyle\]'
    \ || l:tox_ini =~# '\v%(^|\n)\s*\[pep257\]'
    \ || findfile('.pydocstyle', l:bufpath) isnot# ''
    \ || findfile('.pydocstyle.ini', l:bufpath) isnot# ''
    \ || findfile('.pydocstylerc', l:bufpath) isnot# ''
    \ || findfile('.pydocstylerc.ini', l:bufpath) isnot# ''
    \ || findfile('.pep257', l:bufpath) isnot# ''
        call add(l:python_linters, 'pydocstyle')
    endif

    if has_key(l:dependencies, 'pyflakes')
        call add(l:python_linters, 'pyflakes')
    endif

    if has_key(l:dependencies, 'pylama')
    \ || l:pytest_ini =~# '\v%(^|\n)\s*\[pylama(:[^]]+)?\]'
    \ || l:setup_cfg =~# '\v%(^|\n)\s*\[pylama(:[^]]+)?\]'
    \ || l:tox_ini =~# '\v%(^|\n)\s*\[pylama(:[^]]+)?\]'
    \ || search('\m#\s*pylama:', 'cnw')
    \ || findfile('pylama.ini', l:bufpath) isnot# ''
        call add(l:python_linters, 'pylama')
    endif

    if has_key(l:dependencies, 'pylint')
    \ || search('\m#\s*pylint:', 'cnw')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*pylint\s*\.'
    \ || findfile('pylintrc', l:bufpath) isnot# ''
    \ || findfile('.pylintrc', l:bufpath) isnot# ''
        call add(l:python_linters, 'pylint')
    endif

    " python-language-server always applicable
    call add(l:python_linters, 'pyls')

    if has_key(l:dependencies, 'pyre-check')
    \ || findfile('.pyre_configuration', l:bufpath) isnot# ''
        call add(l:python_linters, 'pyre')
    endif

    " https://pyrefly.org/en/docs/configuration/
    if has_key(l:dependencies, 'pyrefly')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*pyrefly\s*\]'
    \ || findfile('pyrefly.toml', l:bufpath) isnot# ''
        call add(l:python_linters, 'pyrefly')
    endif

    " https://microsoft.github.io/pyright/#/configuration
    if has_key(l:dependencies, 'pyright')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*pyright\s*\]'
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\[\s*tool\s*\.\s*pyright\s*\.'
    \ || findfile('pyrightconfig.json', l:bufpath) isnot# ''
        call add(l:python_linters, 'pyright')
    endif

    " https://github.com/dosisod/refurb?tab=readme-ov-file#configuring-refurb
    if has_key(l:dependencies, 'refurb')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*refurb\s*\]'
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\[\s*tool\s*\.\s*refurb\s*\.'
        call add(l:python_linters, 'refurb')
    endif

    " https://docs.astral.sh/ruff/configuration/
    if has_key(l:dependencies, 'ruff')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*ruff\s*[\].]'
    \ || findfile('ruff.toml', l:bufpath) isnot# ''
    \ || findfile('.ruff.toml', l:bufpath) isnot# ''
        call add(l:python_linters, 'ruff')
    endif

    " https://unimport.hakancelik.dev/latest/tutorial/configurations/
    if has_key(l:dependencies, 'unimport')
    \ || l:pyproject_toml =~# '\v%(^|\n)\s*\[\s*tool\s*\.\s*unimport\s*\]'
    \ || l:setup_cfg =~# '\v%(^|\n)\s*\[unimport\]'
        call add(l:python_linters, 'unimport')
    endif

    if has_key(l:dependencies, 'vulture')
        call add(l:python_linters, 'vulture')
    endif

    let &suffixesadd = save_suffixesadd

    return python_linters
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
