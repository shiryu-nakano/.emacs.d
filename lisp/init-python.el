;;; init-python.el --- Python 開発環境  -*- lexical-binding: t; -*-

;; Python のファイルを開くと、次の順に処理する。
;;   1. プロジェクトの .venv（uv が作る仮想環境）を有効にする
;;   2. 言語サーバー（Pyright）を起動する
;; Pyright は .venv の中のパッケージを参照して補完や型検査をおこなう。
;; Pyright が必要（例：uv tool install pyright）。

;; 仮想環境の切り替え
(use-package pyvenv
  :ensure t
  :commands (pyvenv-activate pyvenv-deactivate))

(defun my/python-activate-venv ()
  "開いたファイルより上の階層に .venv があれば、それを有効にする。"
  (let ((root (locate-dominating-file default-directory ".venv")))
    (when root
      (pyvenv-activate (expand-file-name ".venv" root)))))

;; 言語サーバーとの連携
(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l"))     ; LSP のコマンドを C-c l から始める

;; Pyright を言語サーバーとして使う
(use-package lsp-pyright
  :ensure t
  :defer t)

(defun my/python-setup ()
  "仮想環境を有効にしてから言語サーバーを起動する。"
  (my/python-activate-venv)
  (require 'lsp-pyright)
  (lsp-deferred))

(add-hook 'python-mode-hook #'my/python-setup)

;; 補完の候補を表示する
(use-package company
  :ensure t
  :hook (python-mode . company-mode)
  :config
  (setq company-idle-delay 0.2))        ; 0.2秒待ってから候補を表示する

;; 構文と型の検査結果を表示する
(use-package flycheck
  :ensure t
  :hook (python-mode . flycheck-mode))

;; 保存時に整形する（言語サーバーが整形に対応している場合のみ）
(defun my/lsp-format-buffer-if-supported ()
  "Format buffer only if LSP server supports it."
  (when (and (bound-and-true-p lsp-mode)
             (lsp-feature? "textDocument/formatting"))
    (lsp-format-buffer)))

(add-hook 'python-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'my/lsp-format-buffer-if-supported nil t)))

;; デバッガー
(use-package dap-mode
  :ensure t
  :hook (python-mode . dap-auto-configure-mode)
  :config
  (require 'dap-python))

(provide 'init-python)
;;; init-python.el ends here
