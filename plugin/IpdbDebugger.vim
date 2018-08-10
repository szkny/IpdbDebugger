"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <suzuki.s1008 at gmail.com>
" License: MIT license
"=============================================================================
scriptencoding utf-8

if !has('nvim')
    echomsg 'IpdbDebugger.vim requires Neovim.'
    finish
endif

let g:ipdbdebug_map_enabled = get(g:, 'ipdbdebug_map_enabled', 0)
let g:ipdbdebug_command_enabled = get(g:, 'ipdbdebug_command_enabled', 0)

fun! s:ipdb_call(...) abort
    " Ipdbdebuggerのコマンド機能を呼び出す汎用関数
    if ipdbdebug#exist()
        if a:0 > 0
            if a:1 ==# 'close'
                call ipdbdebug#close()
            elseif a:1 ==# 'help'
                call ipdbdebug#jobsend('help')
            elseif a:1 ==# 'maps'
                call ipdbdebug#map_show()
            elseif a:1 ==# 'next'
                call ipdbdebug#jobsend('next')
            elseif a:1 ==# 'step'
                call ipdbdebug#jobsend('step')
            elseif a:1 ==# 'where'
                call ipdbdebug#jobsend('where')
            elseif a:1 ==# 'return'
                call ipdbdebug#jobsend('return')
            elseif a:1 ==# 'break'
                call ipdbdebug#break()
            elseif a:1 ==# 'clear'
                call ipdbdebug#clear()
            elseif a:1 ==# 'continue'
                call ipdbdebug#jobsend('continue')
            elseif a:1 ==# 'until'
                call ipdbdebug#jobsend('until '.line('.'))
            elseif a:1 ==# 'print'
                call ipdbdebug#jobsend('pp '.expand('<cword>'))
            elseif a:1 ==# 'whos'
                call ipdbdebug#whos()
            elseif a:1 ==# 'display'
                call ipdbdebug#jobsend('display '.expand('<cword>'))
            else
                call ipdbdebug#jobsend(join(a:000))
            endif
        else
            call ipdbdebug#jobsend()
        endif
    else
        call ipdbdebug#open()
    endif
endf
fun! s:CompletionIpdbCommands(ArgLead, CmdLine, CusorPos)
    return filter(['close','help','maps','next','step','where','return','break','clear','continue','until','print','whos','display'],
                \printf('v:val =~ "^%s"', a:ArgLead))
endf
command! -complete=customlist,s:CompletionIpdbCommands -nargs=* Ipdb call s:ipdb_call(<f-args>)
