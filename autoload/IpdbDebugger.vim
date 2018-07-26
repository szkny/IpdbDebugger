"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <s.s1008 at gmail.com>
" License: MIT license
"=============================================================================
scriptencoding utf-8

"" ipdbによるPythonデバッガプラグイン
" TODO:
"   - PUDB風にする
"       - ブレークポイントのハイライト
"       - ステップ実行時のカーソル自動移動
"       - スタックトレースの表示
"       - airlineのモードカラー連携
let s:ipdb = {}
let s:ipdb.maps = [
    \['terminal', '<C-d>',      'ipdbdebug#close()'],
    \['normal',   'q',          'ipdbdebug#close()'],
    \['normal',   '<ESC>',      'ipdbdebug#close()'],
    \['normal',   '<C-[>',      'ipdbdebug#close()'],
    \['normal',   '<C-c>',      'ipdbdebug#sigint()'],
    \['normal',   '<CR>',       'ipdbdebug#jobsend()'],
    \['normal',   'i',          'ipdbdebug#goto_debugwin()'],
    \['terminal', '<ESC>',      'ipdbdebug#goto_scriptwin()'],
    \['normal',   '<leader>h',  'ipdbdebug#jobsend("help")'],
    \['normal',   '<leader>n',  'ipdbdebug#jobsend("next")'],
    \['normal',   '<leader>s',  'ipdbdebug#jobsend("step")'],
    \['normal',   '<leader>w',  'ipdbdebug#jobsend("where")'],
    \['normal',   '<leader>r',  'ipdbdebug#jobsend("return")'],
    \['normal',   '<leader>c',  'ipdbdebug#jobsend("continue")'],
    \['normal',   '<leader>b',  'ipdbdebug#jobsend("break ".line("."))'],
    \['normal',   '<leader>u',  'ipdbdebug#jobsend("until ".line("."))'],
    \['normal',   '<leader>p',  'ipdbdebug#jobsend("p ".expand("<cword>"))'],
    \['visual',   '<leader>p',  'ipdbdebug#vprint()'],
\]   " mode       {lhs}         {rhs}
let s:ipdb.map_options = '<script> <silent> <buffer> <nowait>'

fun! ipdbdebug#toggle() abort
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
            silent write
            let s:ipdb.save_cpo = &cpoptions
            setlocal cpoptions&vim
            let s:ipdb.save_updatetime = &updatetime
            setlocal updatetime=100
            setlocal nomodifiable
            if exists('*airline#add_statusline_func')
                silent call airline#add_statusline_func('ipdbdebug#statusline')
            endif
            " キーマッピングの設定
            call s:ipdbdebug#map()
            " autocmdの設定 (定期実行関数の呼び出し)
            aug ipdb_auto_command
                au!
                au CursorHold <buffer> call ipdbdebug#idle()
            aug END
            let s:ipdb.script_winid = win_getid()
            " デバッグウィンドウを開く
            silent call SplitTerm('ipdb3', expand('%'))
            exe 'normal G'
            call s:ipdbdebug#map()
            let s:ipdb.jobid = b:terminal_job_id
            let s:ipdb.debug_winid = win_getid()
            call win_gotoid(s:ipdb.script_winid)
        endif
    else
        echon 'ipdb: [error] invalid file type. this is "' . &filetype. '".'
    endif
endf

fun! ipdbdebug#close()
    " ipdbを終了する関数
    if win_gotoid(s:ipdb.script_winid)
        if exists('*airline#remove_statusline_func')
            silent call airline#remove_statusline_func('ipdbdebug#statusline')
        endif
        let &cpoptions = s:ipdb.save_cpo
        let &updatetime=s:ipdb.save_updatetime
        setlocal modifiable
        call s:ipdbdebug#unmap()
    endif
    aug ipdb_auto_command
        au!
    aug END
    if win_gotoid(s:ipdb.debug_winid)
        quit
    endif
    echon
    unlet s:ipdb.jobid
endf

fun! ipdbdebug#exist() abort
    " ipdbを起動しているか確認する関数
    let l:current_winid = win_getid()
    if has_key(s:ipdb, 'jobid') && has_key(s:ipdb, 'debug_winid')
        \&& win_gotoid(s:ipdb.debug_winid)
        call win_gotoid(l:current_winid)
        return 1
    else
        return 0
    endif
endf

fun! ipdbdebug#idle() abort
    " ipdb起動中に定期的に実行する関数
    " (autocmdを利用している)
    "       au CursorHold <buffer> call ipdbdebug#idle()
    " ipdbdebug#open()関数で、
    "       setlocal updatetime=100
    " と記述して更新間隔を設定 (ミリ秒)
    if ipdbdebug#exist()
        echon '-- DEBUG --'
    else
        call ipdbdebug#close()
    endif
endf

fun! s:ipdbdebug#map()
    " キーマッピングを行う関数
    if has_key(s:ipdb, 'maps') && has_key(s:ipdb, 'map_options')
        for [l:mode, l:map, l:func] in s:ipdb.maps
            let l:cmd = ''
            if l:mode ==? 'n' || l:mode ==? 'normal'
                let l:cmd = 'nno '.s:ipdb.map_options.
                        \' '.l:map.
                        \' '.':<C-u>call <SID>'.l:func.'<CR>'
            elseif l:mode ==? 'v' || l:mode ==? 'visual'
                let l:cmd = 'vno '.s:ipdb.map_options.
                        \' '.l:map.
                        \' '.':<C-u>call <SID>'.l:func.'<CR>'
            elseif l:mode ==? 't' || l:mode ==? 'terminal'
                let l:cmd = 'tno '.s:ipdb.map_options.
                        \' '.l:map.
                        \' '.'<C-\><C-n>:<C-u>call <SID>'.l:func.'<CR>'
            else
                continue
            endif
            silent exe l:cmd
        endfor
    endif
endf
fun! s:ipdbdebug#unmap()
    " キーマッピングを解除する関数
    if has_key(s:ipdb, 'maps') && has_key(s:ipdb, 'map_options')
        for [l:mode, l:map, l:func] in s:ipdb.maps
            if l:mode ==? 'n' || l:mode ==? 'normal'
                let l:cmd = 'nunmap'.s:ipdb.map_options.l:map
            elseif l:mode ==? 'v' || l:mode ==? 'visual'
                let l:cmd = 'vunmap'.s:ipdb.map_options.l:map
            elseif l:mode ==? 't' || l:mode ==? 'terminal'
                let l:cmd = 'tunmap'.s:ipdb.map_options.l:map
            else
                continue
            endif
            try
                silent exe l:cmd
            catch
                continue
            endtry
        endfor
    endif
endf

fun! ipdbdebug#jobsend(...) abort
    " ipdbにコマンドを送る関数
    "    call ipdbdebug#jobsend('ipdbコマンド')
    if ipdbdebug#exist() && a:0 > 0
        let l:command = a:1
        for l:arg in a:000[1:]
            let l:command .= ' ' . l:arg
        endfor
        try
            call jobsend(s:ipdb.jobid, l:command."\<CR>")
        catch
            call ipdbdebug#close()
        endtry
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
        call ipdbdebug#jobsend('p '.l:text)
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
    " idpbのスクリプトウィンドウにいどうする関数
    if ipdbdebug#exist() && has_key(s:ipdb, 'script_winid')
        exe "normal \<C-\>\<C-n>"
        call win_gotoid(s:ipdb.script_winid)
    endif
endf

fun! ipdbdebug#statusline(...)
    " ipdbデバッグモード用のairline(plugin)の設定
    let w:airline_section_a = '%#__accent_bold#IPDB'
    let w:airline_section_b = g:airline_section_b
    let w:airline_section_c = g:airline_section_c
endf
