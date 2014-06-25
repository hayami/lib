;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;;	Key Bindings
;;;

;;; BackSpace (C-h) と Delete キーを交換
;;; Emacs 21.x では交換する必要はないのだが、各種モードで
;;; C-h がヘルプに割り当てられているため、これで回避する。
;(keyboard-translate ?\C-h ?\C-?)
;(keyboard-translate ?\C-? ?\C-h)

;;; C-h で BackSpace
(global-set-key "\C-h" 'backward-delete-char)

;;; M-? [?abc...] でヘルプ
(global-set-key "\M-?" 'help-command)

;;; Mark set は C-SPC から M-SPC に変更
;;; C-SPC は、仮名漢字変換用のキーとして確保
(global-set-key "\M- " 'set-mark-command)

;;; C-x C-b でバッファーメニューのセレクト
(global-set-key "\C-x\C-b" 'buffer-menu)

;;; EOF
