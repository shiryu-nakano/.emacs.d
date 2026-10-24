;;; init-basic.el --- 基本操作とファイルの扱い  -*- lexical-binding: t; -*-

;; init.el を開く
(global-set-key (kbd "C-c e i")
                (lambda () (interactive) (find-file user-init-file)))

;; 設定全体を読み込み直す
;; lisp/ の中のファイルを init.el と同じ順に読み込み、最後に custom.el を読み込む。
;; require は一度読み込んだファイルを読み込み直さないため、load を使う。
(defun my/reload-config ()
  "lisp/ の設定ファイルを init.el と同じ順に読み込み直す。"
  (interactive)
  (dolist (module my/init-modules)
    (load (symbol-name module) nil 'nomessage))
  (when (and custom-file (file-exists-p custom-file))
    (load custom-file nil 'nomessage))
  (message "設定を読み込み直しました"))

(global-set-key (kbd "C-c e e") #'my/reload-config)

;; デバッグ用
;; (setq debug-on-error t)

;; macOS の修飾キー
;; macOS の設定で Control と Command を入れ替えているため、
;; Emacs の中だけ元に戻し、物理的なキーどおりに動くようにする。
;;   物理的な Control → macOS からは Command として届く → Emacs では Control
;;   物理的な Command → macOS からは Control として届く → Emacs では Super
;;   Option           → Emacs では Meta（初期設定のまま）
(when (eq system-type 'darwin)
  (setq ns-command-modifier 'control
        ns-control-modifier 'super))

;; バックアップ、自動保存、ロックファイルを ~/.emacs.d/backups/ にまとめる
(let ((dir (expand-file-name "backups/" user-emacs-directory)))
  (make-directory dir t)
  (setq backup-directory-alist `(("." . ,dir))
        auto-save-file-name-transforms `((".*" ,dir t))
        lock-file-name-transforms `((".*" ,dir t))))

(provide 'init-basic)
;;; init-basic.el ends here
