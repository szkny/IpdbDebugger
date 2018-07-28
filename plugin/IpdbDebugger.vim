"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <suzuki.s1008 at gmail.com>
" License: MIT license
"=============================================================================

if !has('nvim')
    echomsg 'IpdbDebugger.vim requires Neovim.'
    finish
endif

command! IpdbDebug call ipdbdebug#open()
command! IpdbDebugClose call ipdbdebug#close()
command! IpdbDebugToggle call ipdbdebug#toggle()

let g:ipdbdebug_map_enabled = get(g:, 'ipdbdebug_map_enabled', 1)

if g:ipdbdebug_map_enabled
    nno  <silent><C-p> :IpdbDebugToggle<CR>
endif
