;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;; wnn7-egg.el

;;;
;;; OMRON Wnn7 Personal 各種設定
;;;

;(setq wnn7-server-list '("localhost"))
;(setq wnn7-server-user "guest")	; local feature
(require 'wnn7egg-leim)
(set-input-method "japanese-egg-wnn7")
(set-language-info "Japanese" 'input-method "japanese-egg-wnn7")
(setq egg-predict-realtime nil)
(egg-use-input-predict)	; input-method が有効の時じゃないとエラーになる
(inactivate-input-method)

;; かな漢字変換は C-SPC でトグル動作 (これが関係するかも → 『ASCII の範囲に
;; ないコントロール文字をバインドする場合はベクタ表記にする必要があります』)
(define-key global-map "\C-@" 'toggle-input-method)
(define-key global-map [?\C- ] 'toggle-input-method)

;; フェンスモードで C-SPC を押すと [aA] モード (トグル動作)
;; - emacs -nw で起動したときは C-SPC がうまく動いてくれない。C-SPC を押すと、
;;   mini buffer に "ITS:>" と表示され入力待ちになる。そこで、一旦 C-g で逃げ
;;   て、再度 C-SPC を押すと [aA] モードに入ってくれる。
;; - もともとのキーバインディングの C-\ ではこの問題は起こらない。
(define-key fence-mode-map "\C-@" 'fence-toggle-egg-mode)
(define-key fence-mode-map [?\C- ] 'fence-toggle-egg-mode)

;; フェンスモードで C-h は一文字削除
(define-key fence-mode-map "\C-h" 'fence-backward-delete-char)
(define-key fence-mode-map [?\C-h] 'fence-backward-delete-char)

;; フェンスモードで ESC ? を押すとヘルプ (C-h の代わり)
(define-key fence-mode-map "\e?" 'fence-mode-help-command)

;; ESC H (K) で、ひらがな (カタカナ) モードに抜ける (ESC C-h の代わり)
(define-key fence-mode-map "\eH" 'its:select-hiragana)
(define-key fence-mode-map "\eK" 'its:select-katakana)

;; henkan-kakutei-first-char (確定文字列の最初の一文字だけ挿入する)
;; はキーバインドが、カスタマイズしたキーバインドと、相性が悪い。
(define-key wnn7-henkan-mode-map "\C-@" 'wnn7-henkan-quit)
(define-key wnn7-henkan-mode-map [?\C- ] 'wnn7-henkan-quit)

;;;
;;; ローマ字仮名変換ルール (追加分)
;;;
(setq enable-double-n-syntax t)
(setq its:*defrule-verbose* nil)
(its-defrule "dha" "でゃ" nil nil "roma-kana")
(its-defrule "dhi" "でぃ" nil nil "roma-kana")
(its-defrule "dhu" "でゅ" nil nil "roma-kana")
(its-defrule "dhe" "でぇ" nil nil "roma-kana")
(its-defrule "dho" "でょ" nil nil "roma-kana")
(its-defrule "thi" "てぃ" nil nil "roma-kana")
(its-defrule "twu" "とぅ" nil nil "roma-kana")
(its-defrule "wi"  "うぃ" nil nil "roma-kana")
(its-defrule "we"  "うぇ" nil nil "roma-kana")

;;; wnn7-egg.el ends here
