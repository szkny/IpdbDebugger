"=============================================================================
" FILE:    ipdbdebug.vim
" AUTHOR:  Sohei Suzuki <suzuki.s1008 at gmail.com>
" License: MIT license
"=============================================================================
scriptencoding utf-8

"" ipdbによるPythonデバッガプラグイン
" TODO:
"   - ファイルを跨いだ step-in、break point 機能の実装
"   - printのデフォルトは<cword>ではなく左辺値にする
"   - ipdbdebug#map/unmap()のデバッグ
"   - PUDBもしくはllvm.nvim風にする
"       - ステップ実行時のカーソル自動移動
"       - 行のハイライト
"       - スタックトレースの表示
"       - airlineのモードカラー連携

" include guard
if !has('nvim') || exists('g:ipdbdebugger_ipdbdebug_loaded')
    finish
endif
let g:ipdbdebugger_ipdbdebug_loaded = 1

" ipdbdebuggerのインスタンス
let s:ipdb = {}

fun! ipdbdebug#toggle() abort
    " Ipdbの起動/終了を行う関数
    if ipdbdebug#exist()
        call ipdbdebug#close()
    else
        call ipdbdebug#open()
    endif
endf

fun! ipdbdebug#open() abort
    " Ipdbを起動する関数
    if &filetype ==# 'python'
        if !ipdbdebug#exist()
            " ipdbが無ければインストール
            if !executable('ipdb3')
                echon 'Ipdb: [error] ipdb does not exist.'
                echon ' isntalling ipdb ...'
                if !executable('pip')
                    echoerr 'You have to install pip!'
                    return
                endif
                silent call system('pip install ipdb')
                echon
            endif
            " デバッグモードの初期設定
            let s:ipdb.save_cpo = &cpoptions
            setlocal cpoptions&vim
            call s:ipdbinit()
            " キーマッピングの設定
            call ipdbdebug#map()
            " autocmdの設定 (定期実行関数の呼び出し)
            aug ipdb_auto_command
                au!
                au CursorHold <buffer> call ipdbdebug#idle()
            aug END
            let s:ipdb.script_winid = win_getid()
            " デバッグウィンドウを開く
            silent call splitterm#open('ipdb3', expand('%:p'))
            exe 'normal G'
            call s:map_each()
            let s:ipdb.jobid = b:terminal_job_id
            let s:ipdb.debug_winid = win_getid()
            call win_gotoid(s:ipdb.script_winid)
            call ipdbdebug#commands()
        endif
    else
        echon 'ipdb: [error] invalid file type. this is "'.&filetype.'".'
    endif
endf

fun! s:ipdbinit() abort
    " 現在開いている全てのPythonスクリプトのバッファに対して初期設定を行う
    let l:current_bufnr = bufnr('%')
    for l:i in range(0, 10)
        if &filetype ==# 'python'
            silent write
            let s:ipdb.save_updatetime = &updatetime
            setlocal updatetime=100
            setlocal nomodifiable
            if exists('*airline#add_statusline_func')
                silent call airline#add_statusline_func('ipdbdebug#statusline')
            endif
        endif
        silent exe 'bnext'
        if bufnr('%') == l:current_bufnr
            break
        endif
    endfor
endf

fun! s:ipdbfinal() abort
    " 現在開いている全てのPythonスクリプトのバッファに対して終了処理を行う
    let l:current_bufnr = bufnr('%')
    for l:i in range(0, 10)
        if &filetype ==# 'python'
            if exists('*airline#remove_statusline_func')
                silent call airline#remove_statusline_func('ipdbdebug#statusline')
            endif
            let &cpoptions = s:ipdb.save_cpo
            let &updatetime=s:ipdb.save_updatetime
            setlocal modifiable
        endif
        silent exe 'bnext'
        if bufnr('%') == l:current_bufnr
            break
        endif
    endfor
endf

fun! ipdbdebug#close()
    " ipdbを終了する関数
    if win_gotoid(s:ipdb.script_winid)
        call s:ipdbfinal()
        " call ipdbdebug#unmap()
        if has_key(s:ipdb, 'breakpoint')
            unlet s:ipdb.breakpoint
            call clearmatches()
        endif
    endif
    aug ipdb_auto_command
        au!
    aug END
    if win_gotoid(s:ipdb.debug_winid)
        quit
    endif
    echon
    if has_key(s:ipdb, 'jobid')
        unlet s:ipdb.jobid
    endif
    call ipdbdebug#commands()
endf

fun! ipdbdebug#exist() abort
    " ipdbを起動しているか確認する関数
    let l:current_winid = win_getid()
    if has_key(s:ipdb, 'jobid')
      \&& has_key(s:ipdb, 'debug_winid')
        \&& win_gotoid(s:ipdb.debug_winid)
        call win_gotoid(l:current_winid)
        return 1
    else
        return 0
    endif
endf

fun! ipdbdebug#idle() abort
    " ipdb起動中に定期的に実行する関数
    " (autocmdを利用している) au CursorHold <buffer> call ipdbdebug#idle()
    " ipdbdebug#open()関数で、
    "       setlocal updatetime=100
    " と記述して更新間隔を設定 (ミリ秒)
    if ipdbdebug#exist()
        echon '-- DEBUG --'
    else
        call ipdbdebug#close()
    endif
endf


let s:ipdb.maps = [
    \['normal',   '<ESC>',      '<Plug>(ipdbdebug_close)'],
    \['normal',   '<C-[>',      '<Plug>(ipdbdebug_close)'],
    \['normal',   '<leader>q',  '<Plug>(ipdbdebug_close)'],
    \['normal',   '<C-c>',      '<Plug>(ipdbdebug_sigint)'],
    \['normal',   '<CR>',       '<Plug>(ipdbdebug_enter)'],
    \['normal',   '<leader>h',  '<Plug>(ipdbdebug_help)'],
    \['normal',   '<leader>n',  '<Plug>(ipdbdebug_next)'],
    \['normal',   '<leader>s',  '<Plug>(ipdbdebug_step)'],
    \['normal',   '<leader>r',  '<Plug>(ipdbdebug_return)'],
    \['normal',   '<leader>c',  '<Plug>(ipdbdebug_continue)'],
    \['normal',   '<leader>b',  '<Plug>(ipdbdebug_break)'],
    \['normal',   '<leader>u',  '<Plug>(ipdbdebug_until)'],
    \['normal',   '<leader>p',  '<Plug>(ipdbdebug_print)'],
    \['visual',   '<leader>p',  '<Plug>(ipdbdebug_vprint)'],
    \['normal',   '<leader>w',  '<Plug>(ipdbdebug_whos)'],
    \['normal',   '<leader>d',  '<Plug>(ipdbdebug_display)'],
    \['terminal', '<C-d>',      '<C-\><C-n>:<C-u>call ipdbdebug#close()<CR>'],
\]   " mode       {lhs}         {rhs}
    " \['normal',   'i',          '<Plug>(ipdbdebug_goto_debugwin)'],
    " \['terminal', '<ESC>',      '<C-\><C-n>:<C-u>call ipdbdebug#goto_scriptwin()<CR>'],
let s:ipdb.map_options = '<buffer> <nowait>'

fun! ipdbdebug#map() abort
    " 現在開いている全てのPythonスクリプトのバッファに対してマッピングを設定
    if g:ipdbdebug_map_enabled
        let l:current_bufnr = bufnr('%')
        for l:i in range(0, 10)
            if &filetype ==# 'python'
                call s:map_each()
            endif
            silent exe 'bnext'
            if bufnr('%') == l:current_bufnr
                break
            endif
        endfor
    endif
endf

fun! s:map_each() abort
    " キーマッピングを行う関数
    if has_key(s:ipdb, 'maps') && g:ipdbdebug_map_enabled
        let l:map_options = has_key(s:ipdb, 'map_options') ? s:ipdb.map_options : ''
        for [l:mode, l:key, l:plugmap] in s:ipdb.maps
            let l:cmd = ''
            if l:mode ==? 'n' || l:mode ==? 'normal'
                let l:cmd = 'nmap'
            elseif l:mode ==? 'v' || l:mode ==? 'visual'
                let l:cmd = 'vmap'
            elseif l:mode ==? 't' || l:mode ==? 'terminal'
                let l:cmd = 'tmap'
            elseif len(l:mode) == 1
                let l:cmd = l:mode.'map'
            else
                continue
            endif
            let l:cmd .= ' '.l:map_options.' '.l:key.' '.l:plugmap
            silent exe l:cmd
        endfor
    endif
endf

fun! ipdbdebug#unmap() abort
    " キーマッピングを解除する関数
    if has_key(s:ipdb, 'maps')
        let l:map_options = has_key(s:ipdb, 'map_options') ? s:ipdb.map_options : ''
        for [l:mode, l:map, l:func] in s:ipdb.maps
            if l:mode ==? 'n' || l:mode ==? 'normal'
                let l:cmd = 'nunmap'
            elseif l:mode ==? 'v' || l:mode ==? 'visual'
                let l:cmd = 'vunmap'
            elseif l:mode ==? 't' || l:mode ==? 'terminal'
                let l:cmd = 'tunmap'
            elseif len(l:mode) == 1
                let l:cmd = l:mode.'unmap'
            else
                continue
            endif
            let l:cmd .= ' '.s:ipdb.map_options.' '.l:map
            try
                silent exe l:cmd
            catch
                continue
            endtry
        endfor
    endif
endf

fun! ipdbdebug#map_show() abort
    " mappingを確認するための関数
    if has_key(s:ipdb, 'maps') && g:ipdbdebug_map_enabled
        let l:map_options = has_key(s:ipdb, 'map_options') ? s:ipdb.map_options : ''
        for [l:mode, l:key, l:plugmap] in s:ipdb.maps
            let l:cmd = ''
            if l:mode ==? 'n' || l:mode ==? 'normal'
                let l:cmd = 'nmap'
            elseif l:mode ==? 'v' || l:mode ==? 'visual'
                let l:cmd = 'vmap'
            elseif l:mode ==? 't' || l:mode ==? 'terminal'
                let l:cmd = 'tmap'
            elseif len(l:mode) == 1
                let l:cmd = l:mode.'map'
            else
                continue
            endif
            let l:cmd .= ' '.s:ipdb.map_options.' '.l:key.' '.l:plugmap
            echo l:cmd
        endfor
    endif
endf

fun! ipdbdebug#jobsend(...) abort
    " ipdbにコマンドを送る関数
    " USAGE:
    "    call ipdbdebug#jobsend('ipdbのコマンド')
    if ipdbdebug#exist()
        let l:command = ''
        if a:0 > 0
            let l:command = a:1
            for l:arg in a:000[1:]
                let l:command .= ' ' . l:arg
            endfor
        endif
        try
            call jobsend(s:ipdb.jobid, "\<C-u>".l:command."\<CR>")
        catch
            call ipdbdebug#close()
        endtry
    endif
endf

fun! ipdbdebug#break() abort
    " カーソル行をブレークポイントとして設定する関数
    " カーソル行がすでにブレークポイントであれば解除する
    if ipdbdebug#exist()
        let l:line_str = join(split(getline('.'), '\ '))
        if l:line_str ==# ''
                    \|| l:line_str[0] ==# '#'
                    \|| l:line_str[:2] ==# '"""'
                    \|| l:line_str[:2] ==# "'''"
            " コメント行は無視
            call ipdbdebug#jobsend('"*** blank or comment"')
            return
        endif
        let l:current_line = {expand('%:p'): line('.')}
        let l:bp_exist = 0
        if !has_key(s:ipdb, 'breakpoint')
            " ブレークポイントを初めて追加する場合
            let s:ipdb.breakpoint = [l:current_line]
        else
            let l:iter = 0
            for l:bp in s:ipdb.breakpoint
                " 現在行がブレークポイントに設定されているか確認
                if keys(l:bp) ==# keys(l:current_line)
                            \&& values(l:bp) == values(l:current_line)
                    let l:bp_exist = 1
                    break
                endif
                let l:iter += 1
            endfor
            if l:bp_exist
                " 現在行がブレークポイントに設定されている場合
                call remove(s:ipdb.breakpoint, l:iter)
                call s:show_highlight()
                call ipdbdebug#jobsend('clear '.keys(l:current_line)[0].':'.values(l:current_line)[0])
                return
            else
                " 現在行がブレークポイントに設定されていない場合
                if len(s:ipdb.breakpoint) < 8
                    let s:ipdb.breakpoint += [l:current_line]
                else
                    " 8つ以上は matchaddpos() の上限なので追加できない
                    call ipdbdebug#jobsend('"too many breakpoints exist"')
                    return
                endif
            endif
        endif
        call s:show_highlight()
        call ipdbdebug#jobsend('break '.keys(l:current_line)[0].':'.values(l:current_line)[0])
    endif
endf

fun! s:show_highlight() abort
    call clearmatches()
    let l:highlight_line_list = []
    for l:i in s:ipdb.breakpoint
        if keys(l:i)[0] ==# expand('%:p')
            let l:highlight_line_list += [values(l:i)[0]]
        endif
    endfor
    call matchaddpos('IpdbDebugBreakPoint', l:highlight_line_list)
endf

fun! ipdbdebug#clear() abort
    " ブレークポイントを全てクリアする関数
    if ipdbdebug#exist()
        if has_key(s:ipdb, 'breakpoint')
            call clearmatches()
            unlet s:ipdb.breakpoint
            call ipdbdebug#jobsend('clear')
            call ipdbdebug#jobsend('yes')
        endif
    endif
endf

fun! ipdbdebug#sigint() abort
    " ipdbにSIGINT(<C-c>)を送る関数
    if ipdbdebug#exist()
        call jobsend(s:ipdb.jobid, "\<C-c>")
    endif
endf

fun! ipdbdebug#vprint() abort
    " ipdbにvisualモードで選択した変数を送りprintさせる関数
    if ipdbdebug#exist()
        let @@ = ''
        exe 'silent normal gvy'
        if @@ !=# ''
            let l:text = join(split(@@,'\n'))
        else
            let l:text = expand('<cword>')
        endif
        call ipdbdebug#jobsend('pp '.l:text)
    endif
endf

fun! ipdbdebug#whos() abort
    " ipythonのマジックコマンド(%whos)を実行する関数
    if ipdbdebug#exist()
        let l:cmd = 'from IPython import get_ipython;'
                    \.'get_ipython().find_line_magic("whos")()'
        call ipdbdebug#jobsend(l:cmd)
    endif
endf

fun! ipdbdebug#goto_debugwin() abort
    " ipdbのデバッグウィンドウに移動する関数
    if ipdbdebug#exist() && has_key(s:ipdb, 'debug_winid')
        call win_gotoid(s:ipdb.debug_winid)
        startinsert
    endif
endf

fun! ipdbdebug#goto_scriptwin() abort
    " idpbのスクリプトウィンドウに移動する関数
    if ipdbdebug#exist() && has_key(s:ipdb, 'script_winid')
        call win_gotoid(s:ipdb.script_winid)
    endif
endf

fun! ipdbdebug#statusline(...)
    " ipdbデバッグモード用のairline(plugin)の設定
    let w:airline_section_a = '%#__accent_bold#IPDB'
    let w:airline_section_b = g:airline_section_b
    let w:airline_section_c = g:airline_section_c
endf


" プラグインマッピング
tno <buffer><silent> <Plug>(ipdbdebug_close)
            \ <C-\><C-n>:<C-u>call ipdbdebug#close()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_close)
            \ :<C-u>call ipdbdebug#close()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_sigint)
            \ :<C-u>call ipdbdebug#sigint()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_enter)
            \ :<C-u>call ipdbdebug#jobsend()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_help)
            \ :<C-u>call ipdbdebug#jobsend("help")<CR>
nno <buffer><silent> <Plug>(ipdbdebug_next)
            \ :<C-u>call ipdbdebug#jobsend("next")<CR>
nno <buffer><silent> <Plug>(ipdbdebug_step)
            \ :<C-u>call ipdbdebug#jobsend("step")<CR>
nno <buffer><silent> <Plug>(ipdbdebug_where)
            \ :<C-u>call ipdbdebug#jobsend("where")<CR>
nno <buffer><silent> <Plug>(ipdbdebug_return)
            \ :<C-u>call ipdbdebug#jobsend("return")<CR>
nno <buffer><silent> <Plug>(ipdbdebug_continue)
            \ :<C-u>call ipdbdebug#jobsend("continue")<CR>
nno <buffer><silent> <Plug>(ipdbdebug_break)
            \ :<C-u>call ipdbdebug#break()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_clear)
            \ :<C-u>call ipdbdebug#clear()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_until)
            \ :<C-u>call ipdbdebug#jobsend("until ".line("."))<CR>
nno <buffer><silent> <Plug>(ipdbdebug_print)
            \ :<C-u>call ipdbdebug#jobsend("pp ".expand("<cword>"))<CR>
vno <buffer><silent> <Plug>(ipdbdebug_vprint)
            \ :<C-u>call ipdbdebug#vprint()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_whos)
            \ :<C-u>call ipdbdebug#whos()<CR>
nno <buffer><silent> <Plug>(ipdbdebug_display)
            \ :<C-u>call ipdbdebug#jobsend("display ".expand("<cword>"))<CR>
nno <buffer><silent> <Plug>(ipdbdebug_goto_debugwin)
            \ :<C-u>call ipdbdebug#goto_debugwin()<CR>
tno <buffer><silent> <Plug>(ipdbdebug_goto_scriptwin)
            \ <C-\><C-n>:<C-u>call ipdbdebug#goto_scriptwin()<CR>

" コマンド
fun! ipdbdebug#commands() abort
    if ipdbdebug#exist()
        command! -nargs=* IpdbJobsend   call ipdbdebug#jobsend(<f-args>)
        command!          IpdbMaps      call ipdbdebug#map_show()
        command!          IpdbHelp      call ipdbdebug#jobsend('help')
        command!          IpdbNext      call ipdbdebug#jobsend('next')
        command!          IpdbStep      call ipdbdebug#jobsend('step')
        command!          IpdbWhere     call ipdbdebug#jobsend('where')
        command!          IpdbReturn    call ipdbdebug#jobsend('return')
        command!          IpdbBreak     call ipdbdebug#break()
        command!          IpdbClear     call ipdbdebug#clear()
        command!          IpdbContinue  call ipdbdebug#jobsend('continue')
        command!          IpdbUntil     call ipdbdebug#jobsend('until '.line('.'))
        command!          IpdbPrint     call ipdbdebug#jobsend('pp '.expand('<cword>'))
        command! -range   IpdbPrint     call ipdbdebug#vprint()
        command!          IpdbWhos      call ipdbdebug#whos()
        command!          IpdbDisplay   call ipdbdebug#jobsend('display '.expand('<cword>'))
    else
        try
            delcommand IpdbJobsend
            delcommand IpdbMaps
            delcommand IpdbEnter
            delcommand IpdbHelp
            delcommand IpdbNext
            delcommand IpdbStep
            delcommand IpdbWhere
            delcommand IpdbReturn
            delcommand IpdbBreak
            delcommand IpdbClear
            delcommand IpdbContinue
            delcommand IpdbUntil
            delcommand IpdbPrint
            delcommand IpdbWhos
            delcommand IpdbDisplay
        catch
        endtry
    endif
endf

highlight IpdbDebugBreakPoint gui=bold guifg=#00ff00 guibg=#0000ff
