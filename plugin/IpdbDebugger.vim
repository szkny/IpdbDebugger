"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <s.s1008 at gmail.com>
" License: MIT license
"=============================================================================

if !has('nvim')
    echomsg 'IpdbDebugger.vim requires Neovim.'
    finish
endif

nmap <silent><C-p> :IpdbDebug<CR>
command! IpdbDebug call s:ipdb_open()
command! IpdbDebugClose call s:ipdb_close()
command! IpdbDebugToggle call s:ipdb_toggle()
