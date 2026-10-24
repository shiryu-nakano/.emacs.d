;;; init-org.el --- Org Mode とエクスポート  -*- lexical-binding: t; -*-

;; 日付を英語で表記する（December など）
(setq system-time-locale "C")

;; アジェンダとキャプチャのキー（C-c a、C-c c）は init-gtd.el にある

;; =======================================================================
;; ① クリップボードの画像を貼り付ける
;; -----------------------------------------------------------------------
;; macOS の pngpaste コマンドが必要（brew install pngpaste）。
;; 保存先は、貼り付けるファイルの場所によって次のように変わる。
;;   Hugo サイトの中（hugo.toml がある場所）   → static/images/ の下
;;   GTD のフォルダ（org-directory）の中        → org-directory/images/
;;   それ以外                                   → ファイル名_image/
;; org-directory は init-gtd.el で設定している。
;; =======================================================================

(defun org-insert-clipboard-image ()
  "Generate png file from a clipboard image and insert a link to current buffer.
If inside a Hugo site (hugo.toml exists), save to static/images/ with relative path.
If inside `org-directory', save to its images/ directory.
Otherwise, save to filename_image/."
  (interactive)
  (let* ((hugo-root (locate-dominating-file default-directory "hugo.toml")))
    (if hugo-root
        ;; Hugo サイトの中 → static/images/ に保存し、相対パスで参照する
        (let* ((content-dir (expand-file-name "content" hugo-root))
               (current-dir (file-name-directory (buffer-file-name)))
               (relative-path (if (string-prefix-p content-dir current-dir)
                                  (file-relative-name current-dir content-dir)
                                ""))
               (image-dir (expand-file-name
                           (concat "static/images/" relative-path)
                           hugo-root))
               (image-name (format-time-string "%Y%m%d_%H%M%S.png"))
               (image-file (concat image-dir image-name))
               ;; org ファイルから static/images/... への相対パス
               (org-link (file-relative-name image-file current-dir)))
          (make-directory image-dir t)
          (shell-command (concat "pngpaste " image-file))
          (when (file-exists-p image-file)
            (insert (format "#+ATTR_ORG: :width %d\n" 400))
            (insert (concat "[[file:" org-link "]]")))
          (org-display-inline-images))
      ;; Hugo サイトの外
      ;;   GTD のフォルダの中 → org-directory/images/ に保存する
      ;;   それ以外           → ファイル名_image/ に保存する
      (let* ((org-dir (bound-and-true-p org-directory))
             (current-dir (file-name-directory (buffer-file-name)))
             (image-dir (if (and org-dir (file-in-directory-p current-dir org-dir))
                            (expand-file-name "images/" org-dir)
                          (expand-file-name
                           (concat (file-name-nondirectory (buffer-file-name)) "_image/")
                           current-dir)))
             (image-file (expand-file-name
                          (format-time-string "%Y%m%d_%H%M%S.png") image-dir))
             ;; org ファイルから画像への相対パス（projects/ の中なら ../images/...）
             (org-link (file-relative-name image-file current-dir)))
        (make-directory image-dir t)
        (shell-command (concat "pngpaste " (shell-quote-argument image-file)))
        (when (file-exists-p image-file)
          (insert (format "#+ATTR_ORG: :width %d\n" 400))
          (insert (concat "[[file:" org-link "]]")))
        (org-display-inline-images)))))

;; =======================================================================
;; ② LuaLaTeX で PDF を出力する
;; -----------------------------------------------------------------------
;; LuaLaTeX と latexmk が必要（MacTeX などに含まれる）。
;; LaTeX プレビューの設定には影響しない。
;; =======================================================================

(defun my/org-export-to-pdf-with-lualatex ()
  "Export current org buffer to PDF using LuaLaTeX."
  (interactive)
  ;; 下の let で ox-latex の変数を一時的に変えるため、先に読み込んでおく
  (require 'ox-latex)
  (let ((org-latex-compiler "lualatex")
        (org-latex-pdf-process
         '("latexmk -f -pdf -lualatex -interaction=nonstopmode -output-directory=%o %f"))
        (org-latex-packages-alist
         (append '(("" "luatexja" t)
                   ("" "listings" t)
                   ("" "xcolor" t))
                 org-latex-packages-alist))
        ;; listings で枠付きのコードブロックにする
        (org-latex-listings t)
        (org-latex-listings-options
         '(("frame" "single")
           ("basicstyle" "\\ttfamily\\small")
           ("breaklines" "true")))
        ;; LuaLaTeX では inputenc と fontenc は不要
        (org-latex-default-packages-alist
         (seq-remove (lambda (p) (member (cadr p) '("inputenc" "fontenc")))
                     org-latex-default-packages-alist)))
    (org-latex-export-to-pdf)))



;; =======================================================================
;; ③ Org Mode 本体
;; =======================================================================

(use-package org
  :ensure nil                           ; Emacs 標準
  :defer t
  :config
  ;; 画像の表示幅を #+ATTR_ORG で指定できるようにする
  (setq org-image-actual-width nil)

  ;; Emacs 29 以降の Retina 環境で、LaTeX プレビューが2倍の大きさになる問題の修正
  ;; インライン画像の自動拡大を無効にする
  (setq image-scaling-factor 1.0)
  (setq org-format-latex-options
        (plist-put org-format-latex-options :scale 0.9))

  ;; コードブロックで Python を実行できるようにする
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t)))
  ;; 実行前の確認を省く
  (setq org-confirm-babel-evaluate nil)

  ;; キー割り当て
  (global-set-key (kbd "C-x C-y") #'org-insert-clipboard-image)
  (define-key org-mode-map (kbd "C-c e l") #'my/org-export-to-pdf-with-lualatex)

  ;; 見出しを作るキー（macOS で Control と Command を入れ替えているため）
  ;; 物理的な Control キーは Emacs には Command（Super、s-）として届く。
  ;; そこで、s- の組み合わせに見出しを作るコマンドを割り当てる。
  ;;   物理 Control + Enter         → 見出しを作る
  ;;   物理 Control + Shift + Enter → 状態付きの見出しを作る（最初の状態の INBOX が付く）
  (define-key org-mode-map (kbd "s-<return>")   #'org-insert-heading-respect-content)
  (define-key org-mode-map (kbd "s-S-<return>") #'org-insert-todo-heading-respect-content))

;; =======================================================================
;; エクスポート
;; -----------------------------------------------------------------------
;; エクスポートの画面（C-c C-e）を初めて開いたときに読み込まれる。
;; =======================================================================

;; Markdown
(with-eval-after-load 'ox
  (require 'ox-md))

;; Hugo
(use-package ox-hugo
  :ensure t
  :after ox)

;; Jupyter Notebook（MELPA にないため GitHub から取得する）
(use-package ox-ipynb
  :vc (:url "https://github.com/jkitchin/ox-ipynb" :rev :newest)
  :after ox)

(provide 'init-org)
;;; init-org.el ends here
