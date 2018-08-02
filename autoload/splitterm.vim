"=============================================================================
" FILE: IpdbDebugger.vim
" AUTHOR:  Sohei Suzuki <s.s1008 at gmail.com>
" License: MIT license
"=============================================================================
scriptencoding utf-8

" include guard
if !has('nvim') || exists('g:ipdbdebugger_splitterm_loaded')
    finish
endif
let g:ipdbdebugger_splitterm_loaded = 1

fun! splitterm#open(...) abort
    " 分割ウィンドウでターミナルモードを開始する関数
    "      縦分割か横分割かは現在のファイル内の文字数と
    "      ウィンドウサイズとの兼ね合いで決まる
    "      :SplitTerm [Command] で任意のシェルコマンドを実行
    let l:current_dir = expand('%:p:h')
    if l:current_dir[0] !=# '/'
        let l:current_dir = getcwd()
    endif
    " create split window
    let l:width = s:Vsplitwidth()
    if l:width
        let l:split = l:width.'vnew'
    else
        let l:height = s:Splitheight()
        let l:split = l:height ? l:height.'new' : 'new'
    endif
    silent exe l:split
    silent exe 'lcd ' . l:current_dir
    " execute command
    let l:cmd2 = 'terminal'
    if a:0 > 0
        for l:i in a:000
            let l:cmd2 .= ' '.l:i
        endfor
    endif
    silent exe l:cmd2
    " change buffer name
    if a:0 == 0
        silent call s:SetNewBufName('bash')
    elseif a:0 > 0
        silent call s:SetNewBufName(a:1)
    endif
    " set local settings
    setlocal nonumber
    setlocal buftype=terminal
    setlocal filetype=terminal
    setlocal bufhidden=wipe " windowが閉じられた時にバッファを消去
    setlocal nobuflisted    " バッファリストに追加しない
    setlocal nocursorline
    setlocal nocursorcolumn
    " setlocal winfixwidth   " ウィンドウ開閉時に幅を保持
    setlocal noswapfile
    setlocal nomodifiable
    setlocal nolist
    setlocal nospell
    setlocal lazyredraw
endf
command! -complete=shellcmd -nargs=* SplitTerm call SplitTerm(<f-args>)


fun! s:SetNewBufName(name) abort
    " 新規バッファのバッファ名(例: '1:bash')を設定する関数
    "      NewTermとSplitTermで利用している
    let l:num = 1
    let l:name = split(a:name,':')[0]
    while bufexists(l:num.':'.l:name)
        let l:num += 1
    endwhile
    exe 'file '.l:num.':'.l:name
endf


fun! s:Splitheight() abort
    " 新規分割ウィンドウの高さを決める関数
    "      SplitTermで利用している
    let l:min_winheight = 10
    let l:max_winheight = winheight(0)/2
    " count max line length
    let l:height = winheight(0)-line('$')
    let l:height = l:height>l:min_winheight ? l:height : 0
    let l:height = l:height>l:max_winheight ? l:max_winheight : l:height
    return l:height
endf


fun! s:Vsplitwidth() abort
    " 新規分割ウィンドウの幅を決める関数
    "      SplitTermで利用している
    let l:min_winwidth = 60
    let l:max_winwidth = winwidth(0)/2
    " count max line length
    let l:all_lines = getline('w0', 'w$')
    let l:max_line_len = 0
    for l:line in l:all_lines
        if len(l:line) > l:max_line_len
            let l:max_line_len = strwidth(l:line)
        endif
    endfor
    let l:max_line_len += 1
    " count line number or ale column width
    let l:linenumwidth = 0
    if &number
        " add line number column width
        let l:linenumwidth = 4
        let l:digits = 0
        let l:linenum = line('$')
        while l:linenum
            let l:digits += 1
            let l:linenum = l:linenum/10
        endwhile
        if l:digits > 3
            let l:linenumwidth += l:digits - 3
        endif
    endif
    " add ale sign line column width
    if exists('*airline#extensions#ale#get_error')
        \&& (airline#extensions#ale#get_error()!=#'' || airline#extensions#ale#get_warning()!=#'')
            \|| exists('*GitGutterGetHunkSummary') && GitGutterGetHunkSummary() != [0, 0, 0]
        let l:linenumwidth += 2
    endif
    let l:width = winwidth(0)-l:max_line_len-l:linenumwidth
    let l:width = l:width>l:min_winwidth ? l:width : 0
    let l:width = l:width>l:max_winwidth ? l:max_winwidth : l:width
    return l:width
endf
