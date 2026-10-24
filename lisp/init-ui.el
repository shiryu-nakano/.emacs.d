;;; init-ui.el --- 外観  -*- lexical-binding: t; -*-

;; 起動画面、ツールバー、透明化、タイトルバーの設定は early-init.el にある

;; 行番号を常に表示
(global-display-line-numbers-mode t)

;; テーマ（Emacs 標準の manoj-dark）
(load-theme 'manoj-dark t)

(provide 'init-ui)
;;; init-ui.el ends here
