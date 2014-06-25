;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;;	日本語環境
;;;
(set-language-environment "Japanese")

;;; 文字コード
(set-default-coding-systems 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(setq file-name-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;;; Quail Input (非常時用)
(setq quail-japanese-use-double-n t)

;;; Anthy
;(load-library "anthy")
;(setq default-input-method "japanese-anthy")

;;; Info の日本語文字化け対策
(auto-compression-mode t)

;;; EOF
