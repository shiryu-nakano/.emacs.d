;;; init-research.el --- 実験レポートを週報の形式で PDF にする  -*- lexical-binding: t; -*-

;; 実験レポートの置き場所
;;   ResearchLog/weekly/material/<実験名>/<実験名>.org   ← フォルダとファイルは手で作る
;;   ResearchLog/images/                                 ← 貼り付けた画像
;;
;; 主な操作
;;   C-x C-y : 画像を貼り付ける（ResearchLog の中なら ResearchLog/images/ に保存する）
;;   C-c e r : 開いている実験レポートを週報と同じ形式の .tex にし、PDF を作る

(defconst my:researchlog-dir
  (expand-file-name "~/ghq/github.com/shiryu-nakano/ResearchLog/")
  "ResearchLog リポジトリの場所。")

(defconst my:research-author "中野 志颯"
  "実験レポートの著者名。")

(defun my:research--in-researchlog-p ()
  "開いているファイルが ResearchLog の中にあれば t を返す。"
  (and (buffer-file-name)
       (file-in-directory-p (buffer-file-name) my:researchlog-dir)))

;; =======================================================================
;; ① 画像の貼り付け
;; -----------------------------------------------------------------------
;; init-org.el の org-insert-clipboard-image（C-x C-y）に処理を足す。
;; ResearchLog の中では ResearchLog/images/ に保存し、それ以外では元の動作のまま。
;; =======================================================================

(defun my:research--paste-image (orig-fun &rest args)
  "ResearchLog の中では、クリップボードの画像を ResearchLog/images/ に保存して貼る。"
  (if (not (my:research--in-researchlog-p))
      (apply orig-fun args)
    (let* ((current-dir (file-name-directory (buffer-file-name)))
           (image-dir (expand-file-name "images/" my:researchlog-dir))
           (image-file (expand-file-name
                        (format-time-string "%Y%m%d_%H%M%S.png") image-dir))
           ;; .org から画像への相対パス（material/<実験名>/ の中なら ../../../images/...）
           (org-link (file-relative-name image-file current-dir)))
      (make-directory image-dir t)
      (shell-command (concat "pngpaste " (shell-quote-argument image-file)))
      (if (not (file-exists-p image-file))
          (message "クリップボードに画像がありません")
        (insert (format "#+ATTR_ORG: :width %d\n" 400))
        (insert (concat "[[file:" org-link "]]"))
        (org-display-inline-images)))))

(advice-add 'org-insert-clipboard-image :around #'my:research--paste-image)

;; =======================================================================
;; ② 週報と同じ形式の LaTeX クラス
;; -----------------------------------------------------------------------
;; プリアンブルは weekly/2026/week33/week33.tex と同じ。
;; Org が標準で加えるパッケージは入れない。
;; =======================================================================

(with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes
               '("weekly"
                 "\\documentclass[11pt,a4paper]{ltjsarticle}
[NO-DEFAULT-PACKAGES]
[NO-PACKAGES]
\\usepackage{amsmath,amssymb}
\\usepackage{graphicx}
\\usepackage{booktabs}
\\usepackage{hyperref}
\\usepackage[margin=25mm]{geometry}
\\usepackage{float}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

;; =======================================================================
;; ③ 実験レポートを .tex と PDF にする
;; =======================================================================

(defun my:research--fix-latex-output (output backend info)
  "書き出した LaTeX を、週報と同じ書き方に直す。
- #+DATE がないときに Org が書く \\date{} を \\date{\\today} にする。
- 文献ファイルの絶対パスを、.org からの相対パスにする（Mac と Linux の両方でコンパイルできるように）。"
  (if (not (org-export-derived-backend-p backend 'latex))
      output
    (let* ((out (replace-regexp-in-string "^\\\\date{}$" "\\date{\\today}" output t t))
           (src-dir (file-name-directory (plist-get info :input-file)))
           (bib (file-name-sans-extension
                 (expand-file-name "reference/references.bib" my:researchlog-dir))))
      (string-replace (concat "\\bibliography{" bib "}")
                      (concat "\\bibliography{" (file-relative-name bib src-dir) "}")
                      out))))

(defun my:research-export-report ()
  "開いている実験レポートを、週報と同じ形式の .tex にし、lualatex で PDF を作る。
.tex と .pdf は .org と同じフォルダに保存する。"
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Org のファイルで実行してください"))
  (require 'ox-latex)
  (require 'oc)
  (require 'oc-bibtex)
  (save-buffer)
  (let ((org-latex-default-class "weekly")
        (org-latex-compiler "lualatex")
        ;; latexmk を使わず、README の「方法1」と同じ順に毎回実行する。
        ;; Org は PDF を作るたびに latexmk の記録を消すため、latexmk では bibtex が実行されないことがある。
        ;; Org はコマンドの出力すべてから警告を探す。一回目の lualatex は、bibtex の前なので
        ;; 必ず「引用が未定義」と出力する。そのため、最後の一回以外の出力は捨てる。
        ;; 途中の詳しい記録は main.blg と main.log に残る。
        (org-latex-pdf-process
         '("lualatex -interaction=nonstopmode -output-directory=%o %f > /dev/null"
           "bibtex %b > /dev/null"
           "lualatex -interaction=nonstopmode -output-directory=%o %f > /dev/null"
           "lualatex -interaction=nonstopmode -output-directory=%o %f"))
        ;; .log と .blg を残し、警告の中身を確かめられるようにする（.gitignore で除外済み）
        (org-latex-remove-logfiles nil)
        ;; hyperref はクラスで読み込むので、Org の \hypersetup は書かない
        (org-latex-hyperref-template nil)
        ;; 表を \toprule・\midrule・\bottomrule で書く
        (org-latex-tables-booktabs t)
        ;; 図の位置を週報と同じ [H] にする
        (org-latex-default-figure-position "H")
        (org-export-with-toc nil)
        (user-full-name my:research-author)
        ;; [cite:@key] を \cite{key} にし、bibtex の plain で文献の一覧を作る
        (org-cite-global-bibliography
         (list (expand-file-name "reference/references.bib" my:researchlog-dir)))
        (org-cite-export-processors '((latex bibtex "plain")))
        (org-export-filter-final-output-functions
         (cons #'my:research--fix-latex-output
               org-export-filter-final-output-functions)))
    (let ((pdf (org-latex-export-to-pdf)))
      (message "PDF を作りました: %s" pdf))))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c e r") #'my:research-export-report))

(provide 'init-research)
;;; init-research.el ends here
