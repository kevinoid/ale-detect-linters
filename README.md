Detect ALE Linters
==================

A [Vim](https://www.vim.org/) plugin which extends [ALE (Asynchronous Lint
Engine)](https://github.com/w0rp/ale) to detect which linters to use based on
the presence of per-file and per-project linter settings.


## Installation

After installing ALE, this plugin can be installed in the usual ways:

### Using [Vim Packages](https://vimhelp.org/repeat.txt.html#packages)

```sh
git checkout https://github.com/kevinoid/ale-detect-linters.git ~/.vim/pack/git-plugins/start/ale-detect-linters
```

### Using [Pathogen](https://github.com/tpope/vim-pathogen)

```sh
git checkout https://github.com/kevinoid/ale-detect-linters.git ~/.vim/bundles/ale-detect-linters
```

### Using [Vundle](https://github.com/VundleVim/Vundle.vim)

Add the following to `.vimrc`:
```vim
Plugin 'kevinoid/ale-detect-linters'
```
Then run `:PluginInstall`.

### Using [vim-plug](https://github.com/junegunn/vim-plug)

Add the following to `.vimrc` between `plug#begin()` and `plug#end()`:
```vim
Plug 'kevinoid/ale-detect-linters'
```


## Implementation

This plugin is currently implemented by checking for the presence of checker
configuration, both by the presence of configuration files (e.g. `.eslintrc`)
and inline directives in the file being edited (e.g. `/* eslint-disable */`).
The rules are hard coded in per-language
[autoload-functions](https://vimhelp.org/eval.txt.html#autoload-functions).

To customize the behavior of this plugin, users can `set
g:ale_detect_linters = 0` to disable `autocmd` registration, then `let
b:ale_linters = ale#detect#<language>#detectAll(bufnr(''))` with any
desired modifications.


## Collaboration

I would appreciate constructive feedback and suggestions.  I am also willing to
collaborate with any ALE developers who might be interested in
incorporating this functionality into ALE so that it doesn't require a
separate plugin.
