;;; init-blog.el --- ブログの日報と weekly のページ  -*- lexical-binding: t; -*-

;; ブログのリポジトリ（shiryu-nakano.github.io）の content/posts/daily/ に、
;; 日報と weekly のページを作る。
;;
;; 置き場所
;;   日報   : content/posts/daily/<年>/<月>/<年>-<月>-<日>-<曜日>.org  例：2026/11/2026-11-03-Tue.org
;;   weekly : content/posts/daily/<年>/<月>/week-<週番号>.org           例：2026/11/week-45.org
;;
;; 主な操作
;;   C-c n h : 今日の日報を開く。なければヘッダーの後にテンプレート（Templates/daily.org）の中身を入れて作る
;;   C-c n t : 日報のテンプレートを開く
;;   C-c n w : 今週の weekly を開く。なければヘッダーと、月曜から日曜までの日付の一覧を入れたファイルを作る
;;
;; 週番号は ISO 8601 の決め方（月曜始まり）に従う。
;; weekly は、その週の月曜日がある年と月のフォルダに置く。
;; URL の年は ISO 8601 の週の年を使う。12月末の月曜日から始まる週が翌年の第1週になる場合は、
;; URL の年が翌年になる（例：2024/12/week-1.org の URL は /posts/daily/2025/week1/）。

(defconst my/blog-daily-dir
  (expand-file-name "~/ghq/github.com/shiryu-nakano/shiryu-nakano.github.io/content/posts/daily/")
  "日報と weekly を置くフォルダ。")

(defun my/blog--header (title url)
  "日報と weekly に共通するヘッダーを返す。TITLE と URL はそれぞれ #+TITLE と #+URL に入れる。"
  (concat (format "#+TITLE: %s\n" title)
          (format "#+URL: %s\n" url)
          "#+bookToC: false\n"
          "#+OPTIONS: toc:nil num:nil ^:nil tags:nil todo:nil H:10\n"
          "#+OPTIONS: broken-links:mark\n"
          "#+OPTIONS: tex:t\n"
          "#+OPTIONS: html-postamble:nil\n"
          "#+OPTIONS: links:nil\n"
          "\n"))

(defun my/blog--open-or-create (file content)
  "FILE を開く。FILE がなければ CONTENT を書き込んで保存する。
新しく作ったときは t を返す。"
  (let ((new (not (file-exists-p file))))
    (make-directory (file-name-directory file) t)
    (find-file file)
    (when new
      (erase-buffer)
      (insert content)
      (save-buffer))
    new))

(defun my/blog-daily-file (time)
  "TIME の日の日報のファイル名を返す。"
  ;; 曜日を英語の略称（Mon、Tue など）で表記する
  (let ((system-time-locale "C"))
    (expand-file-name (format-time-string "%Y/%m/%Y-%m-%d-%a.org" time)
                      my/blog-daily-dir)))

(defun my/blog-daily-header (time)
  "TIME の日の日報のヘッダーを返す。"
  (let ((system-time-locale "C"))
    (my/blog--header (format-time-string "%Y-%m-%d %a" time)
                     (format-time-string "/posts/daily/%Y/%m/%d/" time))))

(defconst my/blog-daily-template
  (expand-file-name "../../../Templates/daily.org" my/blog-daily-dir)
  "日報の本文のテンプレート。ヘッダー（#+TITLE など）は書かず、見出しなどの本文だけを書く。
リポジトリ直下の Templates/ にあり、content/ の外なのでブログには公開されない。")

(defun my/blog--daily-template-body ()
  "テンプレートの中身を返す。テンプレートがなければ空の文字列を返す。"
  (if (file-exists-p my/blog-daily-template)
      (with-temp-buffer
        (insert-file-contents my/blog-daily-template)
        (buffer-string))
    ""))

(defun my/blog-daily-new-content (time)
  "TIME の日の日報を新しく作るときの中身（ヘッダーとテンプレートの中身）を返す。
`C-c n h' で作るときも、inbox の DONE をコピーするとき（init-gtd.el）も、これを使う。"
  (concat (my/blog-daily-header time)
          (my/blog--daily-template-body)))

(defun my/blog-open-today-daily ()
  "今日の日報を開く。
なければ、今日の日付のヘッダーにテンプレート（`my/blog-daily-template'）の中身を続けたファイルを作る。"
  (interactive)
  (let* ((now  (current-time))
         (file (my/blog-daily-file now)))
    (when (my/blog--open-or-create file (my/blog-daily-new-content now))
      (message "今日の日報を作りました：%s" file))))

(defun my/blog-open-daily-template ()
  "日報のテンプレートを開く。"
  (interactive)
  (find-file my/blog-daily-template))

(defun my/blog--monday (time)
  "TIME を含む週（月曜始まり）の月曜日の時刻を返す。"
  ;; %u は曜日の番号で、月曜が 1、日曜が 7 になる
  (let ((dow (string-to-number (format-time-string "%u" time))))
    (time-subtract time (days-to-time (1- dow)))))

(defun my/blog-open-this-week ()
  "今週の weekly を開く。なければヘッダーと日付の一覧を入れたファイルを作る。"
  (interactive)
  (let* ((system-time-locale "C")
         (monday   (my/blog--monday (current-time)))
         (iso-year (format-time-string "%G" monday))
         (week     (string-to-number (format-time-string "%V" monday)))
         (file     (expand-file-name (format "%s/week-%d.org"
                                             (format-time-string "%Y/%m" monday)
                                             week)
                                     my/blog-daily-dir))
         (title    (format "Week %d" week))
         (url      (format "/posts/daily/%s/week%d/" iso-year week))
         ;; 月曜から日曜までの日付を「- 11/02 Mon」の形で並べる
         (days     (mapconcat (lambda (i)
                                (format-time-string "- %m/%d %a\n"
                                                    (time-add monday (days-to-time i))))
                              (number-sequence 0 6)
                              "")))
    (when (my/blog--open-or-create file
                                   (concat (my/blog--header title url)
                                           (format "* Week %d\n" week)
                                           days))
      (message "今週の weekly を作りました：%s" file))))

(global-set-key (kbd "C-c n h") #'my/blog-open-today-daily)
(global-set-key (kbd "C-c n w") #'my/blog-open-this-week)
(global-set-key (kbd "C-c n t") #'my/blog-open-daily-template)

(provide 'init-blog)
;;; init-blog.el ends here
