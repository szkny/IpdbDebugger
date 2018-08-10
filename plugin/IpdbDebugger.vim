"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <suzuki.s1008 at gmail.com>
" License: MIT license
"=============================================================================

if !has('nvim')
    echomsg 'IpdbDebugger.vim requires Neovim.'
    finish
endif

command! IpdbOpen      call ipdbdebug#open()
command! IpdbClose     call ipdbdebug#close()
command! IpdbToggle    call ipdbdebug#toggle()

let g:ipdbdebug_map_enabled = get(g:, 'ipdbdebug_map_enabled', 0)
