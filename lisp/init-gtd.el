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
;;
;; 主な操作
;;   C-c c t : タスクを inbox に入れる
;;   C-c c i : アイデアを idea に入れる
;;   C-c i   : inbox のファイルを開く
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
  :config
  ;; 見出しの先頭の * を、最後の一つ以外は目立たなくする
  (setq org-hide-leading-stars t)
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

  ;; キャプチャのテンプレート
  ;;   t : inbox ファイルの「inbox」見出しの下にタスクを入れる
  ;;   i : inbox ファイルの「idea」見出しの下にアイデアを入れる
  (setq org-capture-templates
        '(("t" "Task" entry (file+headline org-default-notes-file "inbox")
           "** INBOX %?\n   CREATED: %U\n")
          ("i" "Idea" entry (file+headline org-default-notes-file "idea")
           "** %?\n   CREATED: %U\n")))

  ;; 見出しを移す先は、アジェンダが読むファイルの最上位の見出し
  (setq org-refile-targets '((org-agenda-files :maxlevel . 1)))

  ;; 時間の計測（org-clock）
  (setq org-log-done 'time)                         ; 完了した日時を記録する
  (setq org-clock-clocked-in-display 'frame-title)  ; 計測中のタスク名をウィンドウの題名に表示する

  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture)
   ("C-c g" . org-clock-goto)
   ("C-c i" . my:org-goto-inbox)
   :map org-mode-map
   ("M-n" . org-forward-heading-same-level)
   ("M-p" . org-backward-heading-same-level)))

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
           ((org-agenda-span 1)))))
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
