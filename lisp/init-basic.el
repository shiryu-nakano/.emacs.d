;;; init-basic.el --- 基本操作とファイルの扱い  -*- lexical-binding: t; -*-

;; init.el を開く
(global-set-key (kbd "C-c e i")
                (lambda () (interactive) (find-file user-init-file)))

;; 開いているバッファを評価し直す
;; lisp/ 内のファイルを変更したときは、そのファイルを開いて実行する
(global-set-key (kbd "C-c e e") #'eval-buffer)

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
