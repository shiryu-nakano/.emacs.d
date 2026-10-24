;;; init-gtd.el --- GTD（段階1：収集と実行）  -*- lexical-binding: t; -*-

;; 段階1で使う操作
;;   C-c c t : 思いついた用件を、その年の inbox（inbox2026.org など）に入れる
;;   C-c C-s : （見出しの上で）予定日を付ける
;;   C-c a d : 今日のタスクを表示する
;;   C-c i   : その年の inbox を開く
;;   C-c C-t : 状態を TODO と DONE で切り替える
;; C-c a と C-c c のキー割り当ては init-org.el にある。

;; GTD のファイルを置くフォルダ
(defvar my/org-directory (expand-file-name "~/ghq/github.com/shiryu-nakano/Documents/org/")
  "GTD のファイルを置くフォルダ。")

(defun my/inbox-file ()
  "その時点の年の inbox ファイル（例：inbox2026.org）のパスを返す。"
  (expand-file-name (format-time-string "inbox%Y.org") my/org-directory))

;; フォルダがなければ作る（キャプチャで保存できるようにするため）
(make-directory my/org-directory t)

;; その年の inbox を開く（毎晩、翌日の分に予定日を付けるときに使う）
(global-set-key (kbd "C-c i")
                (lambda () (interactive) (find-file (my/inbox-file))))

(with-eval-after-load 'org
  (setq org-directory my/org-directory)

  ;; アジェンダは my/org-directory にあるすべての .org ファイルを読む
  ;; 前の年の inbox に残ったタスクも表示される
  (setq org-agenda-files (list my/org-directory))

  ;; 状態は TODO と DONE の二つだけ（段階3で WAIT と SOMEDAY を加える）
  (setq org-todo-keywords
        '((sequence "TODO(t)" "|" "DONE(d)")))

  ;; DONE にした日時を記録する（段階2の週次レビューで使う）
  (setq org-log-done 'time)

  ;; キャプチャのテンプレート（入れる先はその時点の年の inbox）
  (setq org-capture-templates
        '(("t" "Task" entry (file my/inbox-file)
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n"
           :empty-lines 1)))

  ;; アジェンダの表示
  (setq org-agenda-custom-commands
        '(("d" "今日" agenda "" ((org-agenda-span 1))))))

(provide 'init-gtd)
;;; init-gtd.el ends here
