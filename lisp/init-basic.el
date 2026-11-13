;;; init-basic.el --- 基本操作とファイルの扱い  -*- lexical-binding: t; -*-

;; init.el を開く
(global-set-key (kbd "C-c e i")
                (lambda () (interactive) (find-file user-init-file)))

;; 設定全体を読み込み直す
;; init.el をそのまま読み込み直す。init.el の中で、すでに読んだ lisp/ のファイルは load で読み直し、
;; 新しく一覧に加えたファイルは require で読み込む。custom.el も init.el の最後で読み込まれる。
;; 読み込み直したファイルの数と、かかった時間を表示する。
(defun my/reload-config ()
  "init.el を読み込み直し、lisp/ の設定ファイルをすべて読み込み直す。"
  (interactive)
  (let ((start (current-time)))
    (load user-init-file nil 'nomessage)
    (message "設定を読み込み直しました（%d 個のファイル、%.2f 秒）: %s"
             (length my/init-modules)
             (float-time (time-subtract (current-time) start))
             (mapconcat #'symbol-name my/init-modules " "))))

(global-set-key (kbd "C-c e e") #'my/reload-config)

;; デバッグ用
;; (setq debug-on-error t)

;; macOS の修飾キー
;; macOS の設定で Control と Command を入れ替えているため、
;;   物理的な Control → Emacs には Command として届く → Meta にする
;;   物理的な Command → Emacs には Control として届く → Control のまま
;;   Option           → Meta（初期設定のまま）
;; 物理的な Control + x で M-x、Control + Enter で M-RET になる。
(when (eq system-type 'darwin)
  (setq ns-command-modifier 'meta))

;; バックアップ、自動保存、ロックファイルを ~/.emacs.d/backups/ にまとめる
(let ((dir (expand-file-name "backups/" user-emacs-directory)))
  (make-directory dir t)
  (setq backup-directory-alist `(("." . ,dir))
        auto-save-file-name-transforms `((".*" ,dir t))
        lock-file-name-transforms `((".*" ,dir t))))

(provide 'init-basic)
;;; init-basic.el ends here
