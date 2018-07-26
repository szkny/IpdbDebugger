"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <s.s1008 at gmail.com>
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

if g:ipdbdebug_map_enabled == 1
    nno  <silent><C-p> :IpdbDebug<CR>
    nmap q          <Plug>(ipdbdebug_close)
    nmap <ESC>      <Plug>(ipdbdebug_close)
    nmap <C-[>      <Plug>(ipdbdebug_close)
    tmap <C-d>      <Plug>(ipdbdebug_close)
    nmap <CR>       <Plug>(ipdbdebug_enter)
    nmap <C-c>      <Plug>(ipdbdebug_sigint)
    nmap i          <Plug>(ipdbdebug_goto_debugwin)
    tmap <ESC>      <Plug>(ipdbdebug_goto_scriptwin)
    nmap <leader>h  <Plug>(ipdbdebug_help)
    nmap <leader>n  <Plug>(ipdbdebug_next)
    nmap <leader>s  <Plug>(ipdbdebug_step)
    nmap <leader>w  <Plug>(ipdbdebug_where)
    nmap <leader>r  <Plug>(ipdbdebug_return)
    nmap <leader>c  <Plug>(ipdbdebug_continue)
    nmap <leader>b  <Plug>(ipdbdebug_break)
    nmap <leader>u  <Plug>(ipdbdebug_until)
    nmap <leader>p  <Plug>(ipdbdebug_print)
    vmap <leader>p  <Plug>(ipdbdebug_vprint)
endif
