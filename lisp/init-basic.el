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

;; 物理的な Control + x で M-x（コマンド名を入力して実行）を開く
;; macOS で Control と Command を入れ替えているため、物理的な Control は Super（s-）として届く。
;; s-x は初期設定では「切り取り」に割り当てられているが、ここで上書きする。
(global-set-key (kbd "s-x") #'execute-extended-command)

;; デバッグ用
;; (setq debug-on-error t)

;; macOS の修飾キー（未決定）
;; macOS 側で Control と Command を入れ替えている場合、
;; 物理的な Control キーを Meta として使うには次の行を有効にする。
;; (setq ns-command-modifier 'meta)

;; バックアップ、自動保存、ロックファイルを ~/.emacs.d/backups/ にまとめる
(let ((dir (expand-file-name "backups/" user-emacs-directory)))
  (make-directory dir t)
  (setq backup-directory-alist `(("." . ,dir))
        auto-save-file-name-transforms `((".*" ,dir t))
        lock-file-name-transforms `((".*" ,dir t))))

(provide 'init-basic)
;;; init-basic.el ends here
