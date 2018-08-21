# IpdbDebugger

## About

IpdbDebugger is a python debuger plugin for Neovim.  
It is based on neovim terminal and ipdb.

## Install

```vim
Plug 'szkny/IpdbDebugger'
```

## TODO
- helpコマンドで表示されるipdbコマンドを全て実装
- printのデフォルトは<cword>ではなく左辺値にする
- マッピング機能のデバッグ
- airlineのモードカラー連携
- PUDBもしくはllvm.nvim風にする
    - ステップ実行時のカーソル自動移動
    - 変数一覧の表示
    - スタックトレースの表示
- シンボリックリンクをインポートしたときのブレークポイントに対応
