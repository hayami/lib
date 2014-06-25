;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;; ~/.emacs.d/init.el

;;;
;;; まず最初に、system-name を FQDN ではなく short name にする
;;; (frame title に FQDN が表示されなくする)
;;;
;;; The symbol system-name is a variable as well as a function. In fact, the
;;; function returns whatever value the variable system-name currently holds.
;;; Thus, you can set the variable system-name in case Emacs is confused about
;;; the name of your system. The variable is also useful for constructing frame
;;; titles (see Frame Titles).
;;;
(setq system-name (car (split-string system-name "\\.")))

;;;
;;; site-lisp とそのサブディレクトリを load-path に加える
;;;
(let ((dir "/usr/local/share/emacs/site-lisp"))
  (when (and
         (not (member dir load-path))
         (file-accessible-directory-p dir))
    (add-to-list 'load-path dir)
    (let ((default-directory dir))
      (normal-top-level-add-subdirs-to-load-path))))

;;;
;;; ~/sys/local/share/emacs/site-lisp があれば load-path に加える
;;;
(let ((dir (expand-file-name "~/sys/local/share/emacs/site-lisp")))
  (when (and
         (not (member dir load-path))
         (file-accessible-directory-p dir))
    (add-to-list 'load-path dir)
    (let ((default-directory dir))
      (normal-top-level-add-subdirs-to-load-path))))

;;;
;;; 各種設定
;;;
(load-file "~/.emacs.d/local-lisp/ja-env.el")
(load-file "~/.emacs.d/local-lisp/keybind.el")
;(setq wnn7-server-list '("localhost"))
;(setq wnn7-server-user "guest")	; local feature
(cond ((require 'wnn7egg-leim nil t)
       (load-file "~/.emacs.d/local-lisp/wnn7-egg.el")))
(cond (window-system
       (load-file "~/.emacs.d/local-lisp/x-client.el")))
(load-file "~/.emacs.d/local-lisp/highlight.el")
(load-file "~/.emacs.d/local-lisp/text-mode.el")
(load-file "~/.emacs.d/local-lisp/shell-mode.el")
(load-file "~/.emacs.d/local-lisp/cc-mode.el")
(load-file "~/.emacs.d/local-lisp/misc.el")

;;; ~/.emacs.d/init.el ends here
