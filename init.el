;;; init.el --- 設定の入口  -*- lexical-binding: t; -*-

;; =======================================================================
;; パッケージ管理
;; -----------------------------------------------------------------------
;; パッケージの初期化は early-init.el の後に Emacs が自動でおこなう。
;; use-package は Emacs 29 以降に標準で含まれる。
;; =======================================================================

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

;; パッケージの一覧を取得していなければ取得する
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)

;; =======================================================================
;; Customize が自動で書き込む設定の保存先
;; -----------------------------------------------------------------------
;; init.el に custom-set-variables が書き込まれないよう、custom.el に分ける。
;; custom.el は Git で管理しない。
;; =======================================================================

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; =======================================================================
;; シェルの環境変数を引き継ぐ
;; -----------------------------------------------------------------------
;; Dock などから起動した Emacs に、zsh で設定した PATH を反映する。
;; =======================================================================

(use-package exec-path-from-shell
  :ensure t
  :if (memq window-system '(mac ns))
  :config
  (exec-path-from-shell-initialize))

;; =======================================================================
;; 機能ごとの設定ファイルを読み込む
;; -----------------------------------------------------------------------
;; 機能を外すときは、該当する行をコメントにする。
;; =======================================================================

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'init-basic)   ; 基本操作、バックアップの保存先
(require 'init-ui)      ; 行番号、テーマ
(require 'init-evil)    ; Evil
(require 'init-tools)   ; neotree、magit
(require 'init-org)     ; Org Mode、エクスポート
(require 'init-gtd)     ; GTD（段階1）
(require 'init-python)  ; Python 開発環境
(require 'init-claude)  ; vterm、Claude Code

;; Customize が書き込んだ設定を最後に読み込む
(load custom-file 'noerror)

;;; init.el ends here
