;;; init-claude.el --- vterm と Claude Code  -*- lexical-binding: t; -*-

;; ターミナル（初回の導入時にビルドするため cmake が必要）
(use-package vterm
  :ensure t
  :bind (:map vterm-mode-map
              ("C-y" . vterm-yank)
              ("M-y" . vterm-yank-pop)
              ("s-v" . vterm-yank)
              ("C-g" . vterm-send-C-g)))

;; Claude Code との連携（MELPA にないため GitHub から取得する）
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest))

;; クリップボードの画像を Claude Code に送る
;; macOS の pngpaste コマンドが必要
(defun claude-code-ide-paste-clipboard-image ()
  "クリップボードの画像をClaude Codeに送信する。"
  (interactive)
  (let* ((filename
          (concat temporary-file-directory
                  "claude-clipboard-"
                  (format-time-string "%Y%m%d_%H%M%S")
                  ".png")))
    (shell-command (concat "pngpaste " filename))
    (if (file-exists-p filename)
        (progn
          ;; パスだけを送る（日本語を含めない）
          (claude-code-ide-send-prompt filename)
          (message "Image sent: %s" filename))
      (user-error "No image in clipboard"))))

(global-set-key (kbd "C-c p") #'claude-code-ide-paste-clipboard-image)

;; vterm からコピーした文章の不要な改行を除く（段落の区切りは残す）
(defun my/normalize-kill-ring ()
  "Kill-ringの最新エントリから不要な改行を除去し整形する。空行（段落区切り）は保持。"
  (interactive)
  (let* ((text (current-kill 0))
         ;; 1. 段落の区切り（2つ以上続く改行）を一時的な目印に置き換える
         (normalized (replace-regexp-in-string "\n\\{2,\\}" "<<PARA>>" text))
         ;; 2. 残りの改行（前後の空白を含む）を空白1つにする
         (normalized (replace-regexp-in-string "[ \t]*\n[ \t]*" " " normalized))
         ;; 3. 目印を改行2つに戻す
         (normalized (replace-regexp-in-string "<<PARA>>" "\n\n" normalized))
         ;; 4. 続く空白を1つにまとめる
         (normalized (replace-regexp-in-string "  +" " " normalized))
         ;; 5. 先頭と末尾の空白を除く
         (normalized (string-trim normalized)))
    (kill-new normalized)
    (message "Normalized (paragraph preserved)")))

(provide 'init-claude)
;;; init-claude.el ends here
