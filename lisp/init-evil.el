;;; init-evil.el --- Evil（Vim のキー操作）  -*- lexical-binding: t; -*-

(use-package evil
  :ensure t
  :config
  (evil-mode 1)
  ;; vterm では Emacs の操作にする（ターミナルにキー入力をそのまま送るため）
  (evil-set-initial-state 'vterm-mode 'emacs))

;; インサートモードで "jj" と打つとノーマルモードに戻る
(use-package key-chord
  :ensure t
  :after evil
  :config
  (setq key-chord-two-keys-delay 0.5)
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state))

(provide 'init-evil)
;;; init-evil.el ends here
