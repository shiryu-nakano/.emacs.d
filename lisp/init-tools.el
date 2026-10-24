;;; init-tools.el --- 汎用ツール  -*- lexical-binding: t; -*-

;; 画面の左にファイルの一覧を表示する
(use-package neotree
  :ensure t
  :bind ("C-c t" . neotree-toggle)
  :config
  (setq neo-smart-open t)           ; 現在のファイルの場所を開く
  (setq neo-window-width 30)        ; ウィンドウの幅
  (setq neo-theme 'ascii))          ; 表示の種類（'icons, 'arrow, 'ascii）

;; Git の操作画面
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(provide 'init-tools)
;;; init-tools.el ends here
