;;; init-gtd.el --- GTD（mamo3gr さんの Qiita 記事の設定をもとにする）  -*- lexical-binding: t; -*-

;; 参考：いきいきと働くためのスクラム+GTDライクなタスク管理と org-mode (Emacs) による実装
;;       https://qiita.com/mamo3gr/items/6324b695131fef9b6031
;;
;; 記事から変えた点
;;   - フォルダとファイルの場所を自分の環境に合わせた
;;   - TODO の状態を INBOX / TODO / WAIT / DONE / CANCEL / SOMEDAY にした
;;   - 状態ごとに色を付けた
;;   - projects/ の中のファイルもアジェンダで読むようにした
;;   - C-m（org-return-indent）は割り当てない。最近の Org では Enter で自動的に字下げされるため
;;   - C-c h（helm-org-in-buffer-headings）は割り当てない。helm を入れていないため
;;   - defadvice は古い書き方のため、advice-add で書き直した
;;   - キャプチャはテンプレートを選ばず、C-c c だけで inbox に入れる。作成日時は記録しない
;;   - inbox のファイルには「inbox」見出しを作らず、最上位の見出しとして入れる
;;   - 見出しを移す先から inbox のファイルを外した
;;   - SOMEDAY の見出しを someday.org にまとめて移すコマンドを加えた
;;   - DONE と CANCEL の見出しを cabinet/archive.org にまとめて移すコマンドを加えた
;;
;; 主な操作
;;   C-c c   : inbox に入れる（INBOX の状態で入る）
;;   C-c i   : inbox のファイルを開く
;;   C-c n s : 開いているファイルの SOMEDAY を someday.org に移す
;;   C-c n a : 開いているファイルで DONE か CANCEL の最上位の見出しを、下の階層ごと cabinet/archive.org に移す
;;   C-c r   : カーソルのある見出しを Reference（cabinet/reference.org）に移す
;;   C-c a i : inbox（INBOX の一覧）
;;   C-c a n : Next Actions（予定日も締め切りもない TODO の一覧）
;;   C-c a w : Waiting For（WAIT の一覧）
;;   INBOX の見出しに予定日（C-c C-s）か締め切り（C-c C-d）を付けると、TODO に変わる
;;   inbox の見出しを DONE にすると、その日のブログの日報にコピーされる（inbox には残る）
;;   C-c n l : inbox にある DONE の見出しを、それぞれ DONE にした日の日報にまとめてコピーする
;;   C-c a a : 今日から2週間の予定
;;   C-c a d : 今日のタスク
;;   C-c a x : 予定日も締め切りもないタスクの一覧
;;   C-c g   : 時間を計測中のタスクへ移動する
;;   C-c C-w : 見出しを別の場所へ移す（refile）
;;   C-c C-x C-i / C-c C-x C-o : 時間の計測を始める / 止める

;; =======================================================================
;; Org Mode 本体（記事の (use-package org ...) にあたる部分）
;; =======================================================================

(use-package org
  :ensure nil                           ; Emacs 標準
  :commands org-agenda
  :init
  ;; GTD のファイルを置くフォルダと、inbox のファイル
  (setq org-directory "~/ghq/github.com/shiryu-nakano/Documents/org/")
  (setq org-default-notes-file (concat org-directory "inbox2026.org"))
  ;; アジェンダが読むファイル
  ;; フォルダを指定すると、その直下の .org ファイルだけを読む（下の階層は読まない）
  ;; そのため projects/ も別に指定する
  (setq org-agenda-files (list org-directory
                               (concat org-directory "projects/")))
  ;; inbox のファイルを開く
  (defun my:org-goto-inbox ()
    (interactive)
    (find-file org-default-notes-file))
  ;; テンプレートを選ばずに inbox へ入れる
  (defun my:org-capture-inbox ()
    (interactive)
    (org-capture nil "t"))
  :config
  ;; 見出しの先頭の * をすべて表示する（記事では t にして、最後の一つ以外を目立たなくしている）
  (setq org-hide-leading-stars nil)
  ;; ファイルを開いたときに見出しを折りたたまない
  (setq org-startup-folded nil)

  ;; TODO の状態
  ;;   INBOX   : 入れたばかりで、まだ何をするか決めていない
  ;;   TODO    : やると決めた行動
  ;;   WAIT    : 他人の返事などを待っている
  ;;   DONE    : 完了
  ;;   CANCEL  : 中止
  ;;   SOMEDAY : いつかやるかもしれない
  ;; | より右は「終わった状態」として扱われ、未完了のタスクの一覧に出ない
  (setq org-todo-keywords
        '((sequence "INBOX(i)" "TODO(t)" "WAIT(w)" "|"
                    "DONE(d)" "CANCEL(c)" "SOMEDAY(s)")))

  ;; 状態ごとの色（M-x list-colors-display で色名の一覧を見られる）
  (setq org-todo-keyword-faces
        '(("INBOX"   . (:foreground "orange"        :weight bold))
          ("TODO"    . (:foreground "deep sky blue" :weight bold))
          ("WAIT"    . (:foreground "yellow"        :weight bold))
          ("DONE"    . (:foreground "forest green"  :weight bold))
          ("CANCEL"  . (:foreground "gray50"        :weight bold))
          ("SOMEDAY" . (:foreground "gray60"        :weight bold))))

  ;; タグ（C-c C-q で付ける。括弧の中の文字で選べる）
  (setq org-tag-alist '(("PROJECT" . ?p) ("MEMO" . ?m) ("PETIT" . ?t)))

  ;; キャプチャのテンプレート（inbox ファイルの末尾に、最上位の見出しとして INBOX で入れる）
  (setq org-capture-templates
        '(("t" "Task" entry (file org-default-notes-file)
           "* INBOX %?\n")))

  ;; 見出しを移す先は、アジェンダが読むファイルの最上位の見出し。
  ;; ただし inbox のファイルは除く（inbox の用件一つ一つが移す先の候補に並ばないようにするため）
  (defun my:org-refile-files ()
    (seq-remove (lambda (f) (file-equal-p f org-default-notes-file))
                (org-agenda-files)))
  (setq org-refile-targets '((my:org-refile-files :maxlevel . 1)))

  ;; 時間の計測（org-clock）
  (setq org-log-done 'time)                         ; 完了した日時を記録する

  ;; SOMEDAY は | より右（終わった状態）にあるため、そのままだと CLOSED の日時が付く。
  ;; SOMEDAY は完了ではないので、SOMEDAY にしたときは CLOSED を消す。
  (defun my:org-remove-closed-for-someday ()
    (when (equal org-state "SOMEDAY")
      (org-add-planning-info nil nil 'closed)))
  (add-hook 'org-after-todo-state-change-hook #'my:org-remove-closed-for-someday)
  (setq org-clock-clocked-in-display 'frame-title)  ; 計測中のタスク名をウィンドウの題名に表示する

  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . my:org-capture-inbox)
   ("C-c g" . org-clock-goto)
   ("C-c i" . my:org-goto-inbox)
   ("C-c r" . my:org-move-to-reference)
   :map org-mode-map
   ("M-n" . org-forward-heading-same-level)
   ("M-p" . org-backward-heading-same-level)))

;; =======================================================================
;; SOMEDAY の見出しを someday.org にまとめて移す
;; -----------------------------------------------------------------------
;; 移す先は org-directory/someday.org の「someday」見出しの下。
;; ファイルや見出しがなければ作る。
;; =======================================================================

(defun my:org-someday-location ()
  "someday.org の「someday」見出しを、org-refile に渡す形で返す。"
  (let ((file (expand-file-name "someday.org" org-directory)))
    (with-current-buffer (find-file-noselect file)
      (org-with-wide-buffer
       (let ((pos (org-find-exact-headline-in-buffer "someday")))
         (unless pos
           (goto-char (point-max))
           (unless (bolp) (insert "\n"))
           (insert "* someday\n")
           (save-buffer)
           (setq pos (org-find-exact-headline-in-buffer "someday")))
         (list "someday" file nil (marker-position pos)))))))

;; =======================================================================
;; 予定日か締め切りを付けたら、INBOX を TODO に変える
;; -----------------------------------------------------------------------
;; C-c C-s（予定日）と C-c C-d（締め切り）の後に実行される。
;; アジェンダの画面で予定日を付けたときも同じように動く。
;; 日付を外したとき（C-u を付けて実行したとき）は何もしない。
;; =======================================================================

(defun my:org-inbox-to-todo-after-date (arg &rest _)
  "日付を付けた見出しが INBOX なら TODO に変える。"
  (unless (equal arg '(4))
    (save-excursion
      (org-back-to-heading t)
      (when (equal (org-get-todo-state) "INBOX")
        (org-todo "TODO")))))

(advice-add 'org-schedule :after #'my:org-inbox-to-todo-after-date)
(advice-add 'org-deadline :after #'my:org-inbox-to-todo-after-date)

;; =======================================================================
;; 見出しを Reference に移す（仮の置き場所：org-directory/cabinet/reference.org）
;; -----------------------------------------------------------------------
;; 行動は不要だが、後で見返したい情報を置く場所。
;; 移すときに INBOX などの状態は外す。
;; cabinet/ はアジェンダが読む範囲に入っていないので、タスクの一覧には出ない。
;; =======================================================================

(defun my:org-move-to-reference ()
  "カーソルのある見出しを、状態を外して cabinet/reference.org の末尾に移す。"
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Org のファイルの中で実行してください"))
  (let ((file (expand-file-name "cabinet/reference.org" org-directory)))
    (make-directory (file-name-directory file) t)
    (unless (file-exists-p file)
      (with-temp-file file (insert "#+title: Reference\n\n")))
    (org-back-to-heading t)
    (when (org-get-todo-state)
      (org-todo 'none))
    (org-refile nil nil (list nil file nil nil))
    (org-save-all-org-buffers)
    (message "Reference に移しました")))

(defun my:org-move-someday ()
  "開いているファイルの SOMEDAY の見出しを、someday.org にまとめて移す。"
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Org のファイルの中で実行してください"))
  (let ((location (my:org-someday-location))
        (markers (org-map-entries #'point-marker "TODO=\"SOMEDAY\"" 'file))
        (count 0))
    (dolist (m markers)
      (save-excursion
        (goto-char m)
        (org-refile nil nil location)
        (setq count (1+ count))))
    (org-save-all-org-buffers)
    (message "%d 件を someday.org に移しました" count)))

(global-set-key (kbd "C-c n s") #'my:org-move-someday)

;; =======================================================================
;; DONE と CANCEL の見出しを cabinet/archive.org にまとめて移す
;; -----------------------------------------------------------------------
;; 移すのは、最上位の見出し（* の見出し）が DONE か CANCEL のものだけ。
;; 下の階層の見出しは、DONE であっても単独では移さない。
;; 最上位の見出しを移すときに、その下の見出しもまとめて移る。
;;
;; Org 標準のアーカイブ（org-archive-subtree）を使う。
;; 移した見出しには、移した日時や元のファイルが ARCHIVE_TIME、ARCHIVE_FILE などのプロパティとして残る。
;; cabinet/ はアジェンダが読む範囲に入っていないので、移した見出しはタスクの一覧に出ない。
;;
;; 画像などの file: リンクが相対パスで書かれていると、移した先のフォルダからはファイルが見つからない。
;; そのため、移す前にリンクのパスを archive.org の場所からの相対パスに書き換える。
;; 例：inbox の [[file:images/a.png]] は、archive.org では [[file:../images/a.png]] になる。
;; 画像のファイルそのものは移さない。
;; =======================================================================

(defun my:org-rewrite-file-links (beg end from-dir to-dir)
  "BEG から END までの相対パスの file: リンクを書き換える。
FROM-DIR からの相対パスを、同じファイルを指す TO-DIR からの相対パスにする。
絶対パス（~/ で始まるものを含む）のリンクは変えない。"
  (save-excursion
    (let ((end (copy-marker end)))
      (goto-char beg)
      (while (re-search-forward "\\[\\[file:\\([^]]+\\)\\]" end t)
        (let* ((target (match-string 1))
               ;; file:a.org::*見出し のような検索の指定は、パスと分けて残す
               (sep    (string-search "::" target))
               (path   (if sep (substring target 0 sep) target))
               (search (if sep (substring target sep) "")))
          (unless (file-name-absolute-p path)
            (replace-match (concat (file-relative-name (expand-file-name path from-dir)
                                                       to-dir)
                                   search)
                           t t nil 1))))
      (set-marker end nil))))

(defun my:org-archive-done ()
  "開いているファイルで DONE か CANCEL の最上位の見出しを、cabinet/archive.org にまとめて移す。
下の階層の見出しも一緒に移る。"
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Org のファイルの中で実行してください"))
  (let* ((file     (expand-file-name "cabinet/archive.org" org-directory))
         (from-dir (file-name-directory (buffer-file-name)))
         (to-dir   (file-name-directory file))
         ;; 「ファイル名::」の形で指定すると、移す先のファイルの最上位の見出しとして入る
         (org-archive-location (concat file "::"))
         ;; 後ろの見出しから順に移す
         (markers (nreverse (org-map-entries #'point-marker
                                             "LEVEL=1+TODO=\"DONE\"|LEVEL=1+TODO=\"CANCEL\""
                                             'file)))
         (count 0))
    (make-directory to-dir t)
    (unless (file-exists-p file)
      (with-temp-file file (insert "#+title: Archive\n\n")))
    (dolist (m markers)
      (goto-char m)
      (org-back-to-heading t)
      ;; 見出しとその下の階層にある file: リンクのパスを書き換えてから移す
      (my:org-rewrite-file-links (point)
                                 (save-excursion (org-end-of-subtree t t))
                                 from-dir to-dir)
      (org-archive-subtree)
      (set-marker m nil)
      (setq count (1+ count)))
    (org-save-all-org-buffers)
    (message "%d 件を cabinet/archive.org に移しました" count)))

(global-set-key (kbd "C-c n a") #'my:org-archive-done)

;; =======================================================================
;; inbox のタスクを DONE にしたら、その日の日報にコピーする
;; -----------------------------------------------------------------------
;; inbox のファイルで見出しを DONE にすると、その見出しと下の階層を、
;; ブログの日報（init-blog.el の my/blog-daily-file）の末尾に最上位の見出しとしてコピーする。
;; inbox の見出しはそのまま残す。
;; アジェンダの画面で DONE にしたときも同じように動く。
;; 日報がなければ、ヘッダーとテンプレート（init-blog.el の my/blog-daily-new-content）で作ってからコピーする。
;; 日報に同じ見出しがすでにあればコピーしない（DONE を付け直したときに二重にならないようにするため）。
;;
;; 日付は DONE にした日（org-extend-today-until を設定していれば、それも反映される）。
;; 画像などの file: リンクは、日報の場所からの相対パスに書き換える。
;; 画像のファイルそのものはコピーしないため、ブログ上では画像が表示されない。
;; 日報はブログ（公開リポジトリ）なので、コピーした内容は push すると公開される。
;; =======================================================================

(defun my:org-inbox-buffer-p ()
  "開いているバッファが inbox のファイルなら t を返す。"
  (and (buffer-file-name)
       (file-equal-p (buffer-file-name) org-default-notes-file)))

(defun my:org-copy-done-to-daily ()
  "inbox の見出しが DONE になったら、その日の日報の末尾にコピーする。"
  (when (and (equal org-state "DONE")
             (my:org-inbox-buffer-p))
    (message "%s" (cdr (my:org-copy-subtree-to-daily (org-current-effective-time))))))

(defun my:org-copy-subtree-to-daily (time)
  "カーソルのある見出しと下の階層を、TIME の日の日報の末尾にコピーする。
日報に同じ DONE の見出しがすでにあればコピーしない。
コピーしたら (t . メッセージ)、しなかったら (nil . メッセージ) を返す。"
  (let* ((file     (my/blog-daily-file time))
         (from-dir (file-name-directory (buffer-file-name)))
         (to-dir   (file-name-directory file))
         ;; 見出しの文字（DONE の後ろ）。日報に同じ見出しがあるかを調べるのに使う
         (title    (save-excursion
                     (org-back-to-heading t)
                     (org-get-heading t t t t)))
         (tree     (save-excursion
                     (org-back-to-heading t)
                     (buffer-substring-no-properties
                      (point) (org-end-of-subtree t t)))))
    ;; file: リンクのパスを、日報の場所からの相対パスに書き換える
    (setq tree (with-temp-buffer
                 (insert tree)
                 (my:org-rewrite-file-links (point-min) (point-max) from-dir to-dir)
                 (buffer-string)))
    (unless (file-exists-p file)
      (make-directory to-dir t)
      (with-temp-file file (insert (my/blog-daily-new-content time))))
    (with-current-buffer (find-file-noselect file)
      (org-with-wide-buffer
       (goto-char (point-min))
       (if (re-search-forward
            (format "^\\*+ +DONE +%s[ \t]*\\(?::.*:\\)?[ \t]*$" (regexp-quote title))
            nil t)
           (cons nil (format "日報にすでにあるのでコピーしませんでした：%s" title))
         (goto-char (point-max))
         (unless (bolp) (insert "\n"))
         ;; 1 を渡すと、最上位の見出しとして貼り付ける
         (org-paste-subtree 1 tree)
         (save-buffer)
         (cons t (format "日報にコピーしました：%s" title)))))))

(add-hook 'org-after-todo-state-change-hook #'my:org-copy-done-to-daily)

;; -----------------------------------------------------------------------
;; inbox にある DONE の見出しを、DONE にした日（CLOSED の日付）の日報にまとめてコピーする
;; -----------------------------------------------------------------------
;; 自動のコピーを入れる前に DONE にしたものを、後からコピーするのに使う。
;; inbox のファイルを開いていなくても、inbox のファイルを対象にする。
;; 下の階層の DONE も対象にする。ただし、親と同じ日に DONE にしたものは
;; 親と一緒にコピー済みなので、二重にはならない。
;; CLOSED の日付がない DONE は飛ばす。

(defun my:org-copy-all-done-to-daily ()
  "inbox にある DONE の見出しを、それぞれ CLOSED の日付の日報にコピーする。"
  (interactive)
  (let ((copied 0) (skipped 0) (no-date 0))
    (with-current-buffer (find-file-noselect org-default-notes-file)
      (org-with-wide-buffer
       ;; 前の見出しから順に処理する（親を子より先にコピーするため）
       (dolist (m (org-map-entries #'point-marker "TODO=\"DONE\"" 'file))
         (goto-char m)
         (let ((closed (org-entry-get nil "CLOSED")))
           (if (not closed)
               (setq no-date (1+ no-date))
             (if (car (my:org-copy-subtree-to-daily (org-time-string-to-time closed)))
                 (setq copied (1+ copied))
               (setq skipped (1+ skipped)))))
         (set-marker m nil))))
    (message "日報に %d 件コピーしました（すでにあった：%d 件、CLOSED の日付がない：%d 件）"
             copied skipped no-date)))

(global-set-key (kbd "C-c n l") #'my:org-copy-all-done-to-daily)

;; =======================================================================
;; アジェンダ（記事の (use-package org-agenda ...) にあたる部分）
;; =======================================================================

(defun my:org-agenda-close-other-windows (&rest _)
  "アジェンダから Enter でタスクへ移動したとき、ほかのウィンドウを閉じる。"
  (delete-other-windows)
  (recenter-top-bottom))

(use-package org-agenda
  :ensure nil                           ; Org に含まれる
  :commands org-agenda
  :config
  (setq org-agenda-custom-commands
        '(("x" "Unscheduled Tasks" tags-todo
           "-SCHEDULED>=\"<today>\"-DEADLINE>=\"<today>\"" nil)
          ("d" "Daily Tasks" agenda ""
           ((org-agenda-span 1)))
          ;; inbox：まだ処理していないもの
          ("i" "Inbox" todo "INBOX")
          ;; Next Actions：やると決めたが、日付を決めていないもの
          ("n" "Next Actions" todo "TODO"
           ((org-agenda-todo-ignore-scheduled 'all)
            (org-agenda-todo-ignore-deadlines 'all)))
          ;; Waiting For：他人の返事などを待っているもの
          ("w" "Waiting For" todo "WAIT")))
  ;; C-c a a で表示する日数（Org の初期値は一週間）。
  ;; C-c a d は、上の設定で一日に指定しているので、この値の影響を受けない。
  ;; 日数を7以外にすると、今週の月曜日からではなく、今日から表示する。
  (setq org-agenda-span 14)
  ;; 完了したタスクを、予定日の欄に表示しない
  (setq org-agenda-skip-scheduled-if-done t)
  ;; リンクの上で Enter を押すとリンク先を開く
  (setq org-return-follows-link t)
  ;; 列の表示で、見積もり時間の合計に予定の時間も含める
  (setq org-agenda-columns-add-appointments-to-effort-sum t)
  ;; 時間の目盛り（9時、12時、13時、18時）
  (setq org-agenda-time-grid
        '((daily today require-timed)
          (0900 1200 1300 1800) "......" "----------------"))
  ;; 列の表示（C-c C-x C-c）で、見積もり時間と計測した時間を表示する
  (setq org-columns-default-format
        "%68ITEM(Task) %6Effort(Effort){:} %6CLOCKSUM(Clock){:}")
  ;; アジェンダから Enter でタスクへ移動したら、ほかのウィンドウを閉じる
  (advice-add 'org-agenda-switch-to :after #'my:org-agenda-close-other-windows)
  :bind
  (:map org-agenda-mode-map
        ("s" . org-agenda-schedule)
        ("S" . org-save-all-org-buffers)))

(provide 'init-gtd)
;;; init-gtd.el ends here
