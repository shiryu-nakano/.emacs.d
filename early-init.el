;;; early-init.el --- 画面を表示する前に読み込む設定  -*- lexical-binding: t; -*-

;; 起動画面を表示しない
(setq inhibit-startup-message t)

;; ツールバーを表示しない
(push '(tool-bar-lines . 0) default-frame-alist)

;; ウィンドウを半透明にする（不透明度80%）
(push '(alpha . 80) default-frame-alist)

;; macOS: タイトルバーを透明にし、暗い配色に合わせる
(when (eq system-type 'darwin)
  (push '(ns-transparent-titlebar . t) default-frame-alist)
  (push '(ns-appearance . dark) default-frame-alist))

;;; early-init.el ends here
