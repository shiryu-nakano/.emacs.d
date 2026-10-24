# .emacs.d

個人用の Emacs 設定。Emacs 30 以降を前提にする（`use-package` の `:vc` 指定を使うため）。

## ファイル構成

| ファイル | 内容 |
|---|---|
| `early-init.el` | 画面を表示する前の設定（起動画面、ツールバー、透明化、タイトルバー） |
| `init.el` | パッケージ管理、`custom.el` の指定、シェルの `PATH` の引き継ぎ、`lisp/` 内のファイルの読み込み |
| `lisp/init-basic.el` | 設定ファイルを開くキー、バックアップの保存先 |
| `lisp/init-ui.el` | 行番号、テーマ（manoj-dark） |
| `lisp/init-evil.el` | Evil、`jj` でノーマルモードに戻る設定 |
| `lisp/init-tools.el` | neotree、magit |
| `lisp/init-org.el` | Org Mode の基本設定、画像の貼り付け、LuaLaTeX での PDF 出力、エクスポート（Markdown、Hugo、Jupyter Notebook） |
| `lisp/init-python.el` | Python 開発環境（`.venv` の自動有効化、Pyright、company、flycheck、dap-mode） |
| `lisp/init-claude.el` | vterm、claude-code-ide |

機能を外すときは、`init.el` の該当する `require` の行をコメントにする。

`custom.el` は Customize が自動で書き込むファイルで、Git では管理しない。

## 主なキー

| キー | 内容 |
|---|---|
| `C-c e i` | init.el を開く |
| `C-c e e` | 開いているバッファを評価し直す |
| `C-c t` | neotree の表示を切り替える |
| `C-x g` | magit を開く |
| `C-c a` / `C-c c` | Org のアジェンダ / キャプチャ |
| `C-x C-y` | クリップボードの画像を Org に貼り付ける |
| `C-c e l` | LuaLaTeX で PDF を出力する（Org の中のみ） |
| `C-c l` | LSP のコマンド（Python） |
| `C-c p` | クリップボードの画像を Claude Code に送る |

## 新しい環境での準備

Emacs の外で、次のコマンドを導入しておく。

```zsh
brew install pngpaste cmake   # 画像の貼り付け、vterm のビルド
uv tool install pyright       # Python の言語サーバー
```

LuaLaTeX での PDF 出力には、LuaLaTeX と latexmk が必要（MacTeX などに含まれる）。

初回の起動時に、パッケージのダウンロードと vterm のビルドがおこなわれる。
