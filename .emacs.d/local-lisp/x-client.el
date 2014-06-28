;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;; x-client.el

;;;;
;;;; X クライアントとして起動した時の設定
;;;;

;;;
;;; 各種設定
;;;
(setq-default mouse-yank-at-point t)		; カーソル位置にペースト
(set-scroll-bar-mode 'right)			; スクロールバーを右側に出す
(mouse-wheel-mode)				; マウス・ホイールを使う
(auto-image-file-mode)				; イメージファイルを表示
(setq-default line-spacing 7)			; 行間
(setq-default indicate-empty-lines t)		; 最終行以降の表示
;(setq-default show-trailing-whitespace t)	; 行末のスペースを強調表示
(tool-bar-mode -1)				; Tool Bar の表示
(blink-cursor-mode 0)				; カーソルの点滅
(setq-default cursor-in-non-selected-windows nil)	; 空カーソルの表示

(custom-set-faces				; 前景色と背景色のデフォルト値
 '(default ((t
             (:foreground "Black"
              :background "#FFFCDE")))))
;(fringe-mode nil)				; 折返し記号 (fringe) 両側あり
(fringe-mode (cons nil nil))			; 折返し記号 (fringe) 左右あり
(set-face-foreground 'fringe "DarkGray")	; Fringe の前景色
(set-face-background 'fringe			; Fringe の背景色
                     (face-background 'default))

(setq initial-frame-alist
(append (list
;        '(background-color . "#FFFCDE")	; このあたりは、Xresources
;        '(width . 80)				; で設定した方がうまくいく。
;        '(height . 49)
;        '(left . 0)
;        '(top . 0)
         '(icon-type . t)			; アイコン (Gnuの絵)
         '(cursor-type . bar)			; カーソルの種類
         ) default-frame-alist))
(setq default-frame-alist initial-frame-alist)

;;;
;;; フォントの設定
;;;
(if (>= emacs-major-version 23)
  (set-default-font "VL Gothic-12")
  (progn
    (create-fontset-from-fontset-spec
     "-*-fixed-medium-r-normal--14-*-*-*-*-*-fontset-14,
      ascii:-*-fixed-medium-r-normal--14-*-iso8859-1,
      japanese-jisx0208:-*-fixed-medium-r-normal--14-*-jisx0208.1983-0,
      katakana-jisx0201:-*-fixed-medium-r-normal--14-*-jisx0201.1976-0")
    (create-fontset-from-fontset-spec
     "-*-fixed-medium-r-normal--16-*-*-*-*-*-fontset-16,
      ascii:-*-fixed-medium-r-normal--16-*-iso8859-1,
      japanese-jisx0208:-*-fixed-medium-r-normal--16-*-jisx0208.1983-0,
      katakana-jisx0201:-*-fixed-medium-r-normal--16-*-jisx0201.1976-0")
    (set-face-font 'default "fontset-14")))

;;;
;;; Pass a URL to a WWW browser --- browse-url.el
;;; (Using Shift-mouse-1 is not desirable because
;;; that event has a standard meaning in Emacs.)
;;;
(autoload 'browse-url-at-mouse "browse-url" nil t)
(global-set-key [S-mouse-2] 'browse-url-at-mouse)
(setq browse-url-netscape-program "firefox")

;;; x-client.el ends here
