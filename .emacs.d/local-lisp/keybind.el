;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;; keybind.el

;;; C-h で BackSpace
(global-set-key (kbd "C-h") 'backward-delete-char)

;;; M-? [?abc...] でヘルプ
(global-set-key (kbd "M-?") 'help-command)

;;; Mark set は C-SPC から M-SPC に変更
;;; C-SPC は、仮名漢字変換用のキーとして確保
(global-set-key (kbd "M-SPC") 'set-mark-command)

;;; C-x C-b でバッファーメニューのセレクト
(global-set-key (kbd "C-x C-b") 'buffer-menu)

;;; keybind.el ends here
