;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;;	その他もろもろ
;;;
(setq make-backup-files nil)		; バックアップファイルは残さない
(custom-set-variables
 '(next-screen-context-lines 1)		; スクロール時の重複行数
 '(truncate-lines nil)			; 行の折り返しあり (デフォルト)
 '(display-time-string-forms		; 日付・時刻のフォーマット
   (quote
    (month "/" day " "
           12-hours ":" minutes am-pm
           (if mail " [New Mail!]" ""))))
;'(lpr-command "lprtxt")		; M-x lpr-{buffer,region} (日本語不可)
;'(lpr-switches nil)
;'(ps-lpr-command "lpr")		; M-x ps-print-{buffer,region}* (同上)
;'(ps-lpr-switches '("-Pps"))
;'(ps-paper-type 'a4)
)
;(display-time)				; 日付・時刻の表示
(setq diff-switches '("-u"))		; default is "-c".
;(setq visible-bell t)			; 警告音

;;; EOF
